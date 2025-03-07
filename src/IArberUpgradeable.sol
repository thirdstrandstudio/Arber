// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IArberUpgradeable {
    event ArbitrageOpportunity(
        address indexed token0, address indexed token1, address bestRouter, address worstRouter, uint256[4] data
    ); //data = uint256 amountIn, uint256 bestPrice, uint256 worstPrice, uint256 profit

    event RouterError(address indexed router, string message);

    struct IteratePairListInput {
        bool shouldIterate;
        uint256 start;
        uint256 amountIn;
        uint256 slippageTolerance;
        uint256 gasUsed;
    }

    struct ArbitrageContext {
        uint256 bestPriceToBuyAsset;
        uint256 bestPriceToSellAsset;
        address buyRouter;
        address sellRouter;
    }

    struct MakeProfitContext {
        bool willMakeProfit;
        address buyRouter;
        address sellRouter;
        uint256 buyAmount;
        uint256 sellAmount;
        uint256 profit;
    }

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

    function getWethPaths(address token, address token1) external view returns (WethPath[] memory);

    function getWethPriceInToken0(address token0, address token1, uint256 gasAmount) external view returns (uint256);

    function executeArbitrage(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 slippageTolerance,
        uint256 gasUsed,
        bool dryRun
    ) external returns (bool);

    function iteratePairList(
        uint256 start,
        uint256 n,
        uint256 amountIn,
        uint256 slippageTolerance,
        uint256 gasUsed,
        bool dryRun
    ) external;

    function getAmountsOut(address router, address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        returns (uint256);

    function addRouter(address router) external;

    function removeRouter(address router) external;

    function getRouters() external view returns (address[] memory);

    function addTokenPair(address token0, address token1) external;

    function clearPairList() external;

    function withdrawTokens(address token) external;
    
    function setWeth(address weth) external;

    function getArbitrageContext(address token0, address token1, uint256 amountIn)
        external
        view
        returns (ArbitrageContext memory);
}
