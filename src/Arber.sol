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
        address indexed token0,
        address indexed token1,
        address bestRouter,
        address worstRouter,
        uint256 amountIn,
        uint256 bestPrice,
        uint256 worstPrice,
        uint256 profit
    );

    EnumerableSet.AddressSet private routers;

    uint256 public slippageTolerance; // e.g., 50 = 0.5%
    uint256 public estimatedGasCost; // approximate gas cost in wei per trade

    struct TokenPair {
        address token0;
        address token1;
    }

    TokenPair[] public pairList;

    function initialize(address[] memory _routers, uint256 _slippageTolerance, uint256 _estimatedGasCost)
        public
        initializer
    {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        slippageTolerance = _slippageTolerance;
        estimatedGasCost = _estimatedGasCost;

        for (uint256 i = 0; i < _routers.length; i++) {
            routers.add(_routers[i]);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function executeArbitrage(address token0, address token1, uint256 amountIn, bool dryRun)
        public
        onlyOwner
        returns (bool)
    {
        uint256 bestPrice;
        uint256 worstPrice = type(uint256).max;
        address bestRouter;
        address worstRouter;

        for (uint256 i = 0; i < routers.length(); i++) {
            uint256 amountOut = getAmountsOut(routers.at(i), token0, token1, amountIn);
            if (amountOut > bestPrice) {
                bestPrice = amountOut;
                bestRouter = routers.at(i);
            }
            if (amountOut < worstPrice) {
                worstPrice = amountOut;
                worstRouter = routers.at(i);
            }
        }

        uint256 minBestPrice = bestPrice - ((bestPrice * slippageTolerance) / 10000);
        uint256 maxWorstPrice = worstPrice + ((worstPrice * slippageTolerance) / 10000);

        uint256 profit = minBestPrice > maxWorstPrice ? minBestPrice - maxWorstPrice : 0;
        if (profit <= estimatedGasCost) {
            return false;
        }

        emit ArbitrageOpportunity(token0, token1, bestRouter, worstRouter, amountIn, bestPrice, worstPrice, profit);

        if (dryRun) {
            return true;
        }

        IERC20(token0).transferFrom(msg.sender, address(this), amountIn);
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
            amountsReceived[1], minBestPrice, path, msg.sender, block.timestamp
        );

        return true;
    }

    function iteratePairList(uint256 start, uint256 n, uint256 amountIn, bool dryRun) external onlyOwner {
        uint256 len = pairList.length;
        require(len > 0, "pairList is empty");

        for (uint256 i = 0; i < n; i++) {
            uint256 index = (start + i) % len;
            executeArbitrage(pairList[index].token0, pairList[index].token1, amountIn, dryRun);
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

    function setSlippageTolerance(uint256 _slippageTolerance) external onlyOwner {
        slippageTolerance = _slippageTolerance;
    }

    function setEstimatedGasCost(uint256 _estimatedGasCost) external onlyOwner {
        estimatedGasCost = _estimatedGasCost;
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
        pairList.push(TokenPair(token0, token1));
    }

    function clearPairList() external onlyOwner {
        delete pairList;
    }

    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}
