// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract BscAmmArbitrage is Ownable {

    address[] public routers;

    constructor(address[] memory _routers) Ownable(msg.sender) {
        routers = _routers;
    }

    function executeArbitrage(
        address token0,
        address token1,
        uint amountIn
    ) external onlyOwner {
        uint bestPrice;
        uint worstPrice = type(uint).max;
        address bestRouter;
        address worstRouter;

        // Find best and worst prices from AMMs
        for(uint i=0; i<routers.length; i++) {
            uint amountOut = getAmountsOut(routers[i], token0, token1, amountIn);
            if(amountOut > bestPrice) {
                bestPrice = amountOut;
                bestRouter = routers[i];
            }
            if(amountOut < worstPrice) {
                worstPrice = amountOut;
                worstRouter = routers[i];
            }
        }

        require(bestPrice > worstPrice, "No profitable arbitrage");

        // Execute trade: buy from worst, sell to best
        IERC20(token0).transferFrom(msg.sender, address(this), amountIn);
        IERC20(token0).approve(worstRouter, amountIn);

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        uint[] memory amountsReceived = IUniswapV2Router02(worstRouter).swapExactTokensForTokens(
            amountIn, 0, path, address(this), block.timestamp
        );

        IERC20(token1).approve(bestRouter, amountsReceived[1]);

        path[0] = token1;
        path[1] = token0;

        IUniswapV2Router02(bestRouter).swapExactTokensForTokens(
            amountsReceived[1], 0, path, msg.sender, block.timestamp
        );
    }

    function getAmountsOut(address router, address tokenIn, address tokenOut, uint amountIn) public view returns(uint) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint[] memory amounts = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function setRouters(address[] memory _routers) external onlyOwner {
        routers = _routers;
    }

    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}
