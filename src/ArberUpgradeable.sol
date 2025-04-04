// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IArberUpgradeable.sol";

contract ArberUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable, IArberUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private routers;
    address public weth;
    mapping(address => mapping(address => TokenPair)) private pairMapping;
    TokenPair[] public pairList;

    function initialize(address[] memory _routers, address _weth) public initializer {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
        for (uint256 i = 0; i < _routers.length; i++) {
            routers.add(_routers[i]);
        }
        weth = _weth;
    }

    function getWethPaths(address token, address token1) public view override returns (WethPath[] memory) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        uint256 count = 0;
        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            uint256 amount = getAmountsOut(router, path[0], path[1], 1 ether);
            if (amount > 0) {
                count++;
            }
        }

        // Allocate memory array
        WethPath[] memory wethPaths = new WethPath[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            uint256 amount = getAmountsOut(router, path[0], path[1], 1 ether);
            if (amount > 0) {
                wethPaths[index] = WethPath(path, router);
                index++;
            }
        }

        if (wethPaths.length > 0) {
            return wethPaths;
        }

        // Check token1 if no paths found initially
        path[1] = token1;
        count = 0;

        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            uint256 amount = getAmountsOut(router, path[0], path[1], 1 ether);
            if (amount > 0) {
                count++;
            }
        }

        wethPaths = new WethPath[](count);
        index = 0;

        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            uint256 amount = getAmountsOut(router, path[0], path[1], 1 ether);
            if (amount > 0) {
                wethPaths[index] = WethPath(path, router);
                index++;
            }
        }
        return wethPaths;
    }

    function getWethPriceInToken0(address token0, address token1, uint256 gasAmount)
        public
        view
        override
        returns (uint256)
    {
        if (gasAmount == 0) {
            return 0;
        }
        TokenPair memory pair = pairMapping[token0][token1];
        require(pair.wethPaths.length > 0, "Need more than one weth path");

        WethPath memory firstPath = pair.wethPaths[0];

        bool isToken0 = firstPath.paths[1] == token0;
        if (isToken0) {
            return getAmountsOut(firstPath.router, firstPath.paths[0], firstPath.paths[1], gasAmount);
        }
        uint256 priceInToken1 = getAmountsOut(firstPath.router, firstPath.paths[0], firstPath.paths[1], gasAmount);
        if (priceInToken1 == 0) {
            return 0;
        }
        return getAmountsOut(firstPath.router, token1, token0, priceInToken1);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getArbitrageContext(address token0, address token1, uint256 amountIn)
        public
        view
        override
        returns (ArbitrageContext memory)
    {
        uint256 bestPriceToBuyAsset;
        uint256 bestPriceToSellAsset;
        address buyRouter;
        address sellRouter;
        TokenPair memory tokenPair = pairMapping[token0][token1];

        for (uint256 i = 0; i < tokenPair.routers.length; i++) {
            try this.getAmountsOut(tokenPair.routers[i], token0, token1, amountIn) returns (uint256 amountOut) {
                if (amountOut > bestPriceToBuyAsset) {
                    bestPriceToBuyAsset = amountOut;
                    buyRouter = tokenPair.routers[i];
                }
            } catch {
                bestPriceToBuyAsset = 0;
                buyRouter = address(0);
            }
        }

        if (buyRouter != address(0)) {
            for (uint256 i = 0; i < tokenPair.routers.length; i++) {
                try this.getAmountsOut(tokenPair.routers[i], token1, token0, bestPriceToBuyAsset) returns (
                    uint256 amountOut
                ) {
                    if (amountOut > bestPriceToSellAsset) {
                        bestPriceToSellAsset = amountOut;
                        sellRouter = tokenPair.routers[i];
                    }
                } catch {
                    bestPriceToSellAsset = 0;
                    sellRouter = address(0);
                }
            }
        }

        return ArbitrageContext(bestPriceToBuyAsset, bestPriceToSellAsset, buyRouter, sellRouter);
    }

    //Slippage tolerance 50 = 0.5%
    function executeArbitrage(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 slippageTolerance,
        uint256 gasUsed,
        bool dryRun
    ) public override onlyOwner returns (bool) {
        if (gasUsed == 0) {
            gasUsed = gasleft();
        }
        MakeProfitContext memory makeProfitContext =
            willMakeProfit(token0, token1, amountIn, slippageTolerance, gasUsed);

        if (!makeProfitContext.willMakeProfit) {
            return false;
        }

        uint256 buyAmount = makeProfitContext.buyAmount;
        uint256 sellAmount = makeProfitContext.sellAmount;
        uint256 profit = makeProfitContext.profit;
        address buyRouter = makeProfitContext.buyRouter;
        address sellRouter = makeProfitContext.sellRouter;

        uint256[4] memory data;
        data[0] = amountIn;
        data[1] = buyAmount;
        data[2] = sellAmount;
        data[3] = profit;
        emit ArbitrageOpportunity(token0, token1, buyRouter, sellRouter, data);

        if (dryRun) {
            return true;
        }

        if (IERC20(token0).balanceOf(address(this)) < amountIn) {
            emit RouterError(buyRouter, "Not enough balance");
            return false;
        }

        //IERC20(token0).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(token0).approve(buyRouter, amountIn);

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256[] memory amountsReceived = IUniswapV2Router02(buyRouter).swapExactTokensForTokens(
            amountIn, buyAmount, path, address(this), block.timestamp
        );

        // After first swap, compute expected return for the reverse swap:
        IERC20(token1).approve(sellRouter, amountsReceived[1]);

        address[] memory reversePath = new address[](2);
        reversePath[0] = token1;
        reversePath[1] = token0;

        IUniswapV2Router02(sellRouter).swapExactTokensForTokens(
            amountsReceived[1], sellAmount, reversePath, address(this), block.timestamp
        );

        return true;
    }

    function willMakeProfit(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 slippageTolerance,
        uint256 gasUsed
    ) internal view returns (MakeProfitContext memory) {
        ArbitrageContext memory context = this.getArbitrageContext(token0, token1, amountIn);
        uint256 bestPriceToBuyAsset = context.bestPriceToBuyAsset;
        uint256 bestPriceToSellAsset = context.bestPriceToSellAsset;
        address buyRouter = context.buyRouter;
        address sellRouter = context.sellRouter;

        if (sellRouter == address(0) || buyRouter == address(0)) {
            return MakeProfitContext(false, buyRouter, sellRouter, 0, 0, 0);
        }

        uint256 buyAmount = bestPriceToBuyAsset - ((bestPriceToBuyAsset * slippageTolerance) / 10000);
        uint256 sellAmount = bestPriceToSellAsset - ((bestPriceToSellAsset * slippageTolerance) / 10000);

        uint256 profit = sellAmount > amountIn ? sellAmount - amountIn : 0;
        uint256 wPrice = getWethPriceInToken0(token0, token1, gasUsed);
        if (profit <= wPrice) {
            return MakeProfitContext(false, buyRouter, sellRouter, buyAmount, sellAmount, profit);
        }
        return MakeProfitContext(true, buyRouter, sellRouter, buyAmount, sellAmount, profit);
    }

    function shouldIteratePairList(
        uint256 start,
        uint256 n,
        uint256 amountIn,
        uint256 slippageTolerance,
        uint256 gasUsed
    ) public view returns (IteratePairListInput memory) {
        uint256 gasStart = gasUsed;
        uint256 gasDividedPerTx = gasStart / n;
        uint256 len = pairList.length;

        for (uint256 i = 0; i < n; i++) {
            uint256 index = (start + i) % len;
            MakeProfitContext memory makeProfitContext = willMakeProfit(
                pairList[index].token0, pairList[index].token1, amountIn, slippageTolerance, gasDividedPerTx
            );
            if (makeProfitContext.willMakeProfit) {
                return IteratePairListInput(true, index, amountIn, slippageTolerance, gasDividedPerTx);
            }
        }
        return IteratePairListInput(false, start, amountIn, slippageTolerance, gasDividedPerTx);
    }

    function iteratePairList(
        uint256 start,
        uint256 n,
        uint256 amountIn,
        uint256 slippageTolerance,
        uint256 gasUsed,
        bool dryRun
    ) public override onlyOwner {
        uint256 gasStart = gasUsed == 0 ? gasleft() : gasUsed;
        uint256 gasDividedPerTx = gasStart / n;
        uint256 len = pairList.length;
        require(len > 0, "pairList is empty");

        for (uint256 i = 0; i < n; i++) {
            uint256 index = (start + i) % len;
            executeArbitrage(
                pairList[index].token0, pairList[index].token1, amountIn, slippageTolerance, gasDividedPerTx, dryRun
            );
        }
    }

    function getAmountsOut(address router, address tokenIn, address tokenOut, uint256 amountIn)
        public
        view
        override
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        try IUniswapV2Router02(router).getAmountsOut(amountIn, path) returns (uint256[] memory amounts) {
            return amounts[1];
        } catch {
            return 0;
        }
    }

    function addRouter(address router) public override onlyOwner {
        routers.add(router);
    }

    function setWeth(address _weth) public override onlyOwner {
        weth = _weth;
    }

    function removeRouter(address router) public override onlyOwner {
        routers.remove(router);
    }

    function getRouters() public view override returns (address[] memory) {
        return routers.values();
    }

    function addTokenPair(address token0, address token1) public override onlyOwner {
        // First, count the number of routers that meet the condition
        uint256 count = 0;
        for (uint256 i = 0; i < routers.length(); i++) {
            address routerAddress = routers.at(i);
            uint256 amountOut = getAmountsOut(routerAddress, token0, token1, 1 ether);
            if (amountOut > 0) {
                count++;
            }
        }

        require(count > 1, "Need more than one router to add pair");
        require(pairMapping[token0][token1].wethPaths.length == 0, "Pair already exists");

        // Create a memory array with the exact size needed
        address[] memory routerList = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < routers.length(); i++) {
            address routerAddress = routers.at(i);
            uint256 amountOut = getAmountsOut(routerAddress, token0, token1, 1 ether);
            if (amountOut > 0) {
                routerList[index] = routerAddress;
                index++;
            }
        }

        WethPath[] memory wethPaths = getWethPaths(token0, token1);
        require(wethPaths.length > 0, "No wethpaths found");

        TokenPair memory tokenPair = TokenPair(token0, token1, routerList, wethPaths);
        pairList.push(tokenPair);
        pairMapping[token0][token1] = tokenPair;
    }

    function clearPairList() public override onlyOwner {
        delete pairList;
    }

    function withdrawTokens(address token) public override onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}
