// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ArberUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    event ArbitrageOpportunity(
        address indexed token0, address indexed token1, address bestRouter, address worstRouter, uint256[4] data
    ); //data = uint256 amountIn, uint256 bestPrice, uint256 worstPrice, uint256 profit

    event RouterError(
        address indexed router,
        string message
    );

    EnumerableSet.AddressSet private routers;
    address public weth;
    mapping(address => mapping(address => TokenPair)) private pairMapping;

    struct WethPath {
        address[] paths;
        address router;
    }

    struct TokenPair {
        address token0;
        address token1;
        address[] routers;
        WethPath[] wethPaths;
    }

    TokenPair[] public pairList;

    function initialize(address[] memory _routers) public initializer {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
        for (uint256 i = 0; i < _routers.length; i++) {
            routers.add(_routers[i]);
        }
    }

    function getWethPaths(address token, address token1) public view returns (WethPath[] memory) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;

        uint256 count = 0;
        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            try IUniswapV2Router02(router).getAmountsOut(1 ether, path) returns (uint256[] memory amounts) {
                if (amounts[1] > 0) {
                    count++;
                }
            } catch {}
        }

        // Allocate memory array
        WethPath[] memory wethPaths = new WethPath[](count);

        uint256 index = 0;
        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            try IUniswapV2Router02(router).getAmountsOut(1 ether, path) returns (uint256[] memory amounts) {
                if (amounts[1] > 0) {
                    wethPaths[index] = WethPath(path, router);
                    index++;
                }
            } catch {}
        }

        if (wethPaths.length > 0) {
            return wethPaths;
        }

        // Check token1 if no paths found initially
        path[1] = token1;
        count = 0;

        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            try IUniswapV2Router02(router).getAmountsOut(1 ether, path) returns (uint256[] memory amounts) {
                if (amounts[1] > 0) {
                    count++;
                }
            } catch {}
        }

        wethPaths = new WethPath[](count);
        index = 0;

        for (uint256 i = 0; i < routers.length(); i++) {
            address router = routers.at(i);
            try IUniswapV2Router02(router).getAmountsOut(1 ether, path) returns (uint256[] memory amounts) {
                if (amounts[1] > 0) {
                    wethPaths[index] = WethPath(path, router);
                    index++;
                }
            } catch {}
        }

        return wethPaths;
    }

    function getWethPriceInToken0(address token0, address token1) public view returns (uint256) {
        TokenPair memory pair = pairMapping[token0][token1];
        require(pair.wethPaths.length > 0, "Need more than one weth path");

        WethPath memory firstPath = pair.wethPaths[0];

        bool isToken0 = firstPath.paths[0] == token0;
        if (isToken0) {
            return getAmountsOut(firstPath.router, firstPath.paths[1], firstPath.paths[0], 1 ether);
        }
        uint256 priceInToken1 = getAmountsOut(firstPath.router, firstPath.paths[1], firstPath.paths[0], 1 ether);
        return getAmountsOut(firstPath.router, token1, token0, priceInToken1);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    //Slippage tolerance 50 = 0.5%
    function executeArbitrage(address token0, address token1, uint256 amountIn, uint256 slippageTolerance, uint256 gasUsed, bool dryRun)
        public
        onlyOwner
        returns (bool)
    {
        if (gasUsed == 0) {
            gasUsed = gasleft();
        }
        uint256 bestPrice;
        uint256 worstPrice = type(uint256).max;
        address bestRouter;
        address worstRouter;
        TokenPair memory tokenPair = pairMapping[token0][token1];

        for (uint256 i = 0; i < tokenPair.routers.length; i++) {
            try this.getAmountsOut(tokenPair.routers[i], token0, token1, amountIn) returns (uint256 amountOut) {
                if (amountOut > bestPrice) {
                    bestPrice = amountOut;
                    bestRouter = tokenPair.routers[i];
                }
                if (amountOut < worstPrice) {
                    worstPrice = amountOut;
                    worstRouter = tokenPair.routers[i];
                }
            } catch {
                emit RouterError(tokenPair.routers[i], "Failed to fetch price");
            }
        }

        if(bestRouter == address(0) || worstRouter == address(0)) {
            return false;
        }

        uint256 minBestPrice = bestPrice - ((bestPrice * slippageTolerance) / 10000);
        uint256 maxWorstPrice = worstPrice + ((worstPrice * slippageTolerance) / 10000);

        uint256 profit = minBestPrice > maxWorstPrice ? minBestPrice - maxWorstPrice : 0;
        if (profit <= (gasUsed * getWethPriceInToken0(token0, token1))) {
            return false;
        }

        uint256[4] memory data;
        data[0] = amountIn;
        data[1] = bestPrice;
        data[2] = worstPrice;
        data[3] = profit;
        emit ArbitrageOpportunity(token0, token1, bestRouter, worstRouter, data);

        if (dryRun) {
            return true;
        }

        IERC20(token0).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(token0).approve(worstRouter, amountIn);

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint256[] memory amountsReceived = IUniswapV2Router02(worstRouter).swapExactTokensForTokens(
            amountIn, maxWorstPrice, path, address(this), block.timestamp
        );

        IERC20(token1).approve(bestRouter, amountsReceived[1]);

        path[0] = token1;
        path[1] = token0;

        IUniswapV2Router02(bestRouter).swapExactTokensForTokens(
            amountsReceived[1], minBestPrice, path, _msgSender(), block.timestamp
        );

        return true;
    }

    function iteratePairList(uint256 start, uint256 n, uint256 amountIn, uint256 slippageTolerance, bool dryRun) external onlyOwner {
        uint256 gasStart = gasleft();
        uint256 gasDividedPerTx = gasStart / n;
        uint256 len = pairList.length;
        require(len > 0, "pairList is empty");

        for (uint256 i = 0; i < n; i++) {
            uint256 index = (start + i) % len;
            executeArbitrage(pairList[index].token0, pairList[index].token1, amountIn, slippageTolerance, gasDividedPerTx, dryRun);
        }
    }

    function getAmountsOut(address router, address tokenIn, address tokenOut, uint256 amountIn)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function addRouter(address router) external onlyOwner {
        routers.add(router);
    }

    function removeRouter(address router) external onlyOwner {
        routers.remove(router);
    }

    function getRouters() external view returns (address[] memory) {
        return routers.values();
    }

    function addTokenPair(address token0, address token1) external onlyOwner {
        // First, count the number of routers that meet the condition
        uint256 count = 0;
        for (uint256 i = 0; i < routers.length(); i++) {
            address routerAddress = routers.at(i);
            uint256 amountOut = getAmountsOut(routerAddress, token0, token1, 1 ether);
            if (amountOut > 0) {
                count++;
            }
        }

        require(count > 0, "No routers have pair");

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

    function clearPairList() external onlyOwner {
        delete pairList;
    }

    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}
