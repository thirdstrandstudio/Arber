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

    EnumerableSet.AddressSet private routers;

    struct TokenPair {
        address token0;
        address token1;
    }

    TokenPair[] public pairList;

    function initialize(address[] memory _routers) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        for(uint i = 0; i < _routers.length; i++) {
            routers.add(_routers[i]);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function executeArbitrage(
        address token0,
        address token1,
        uint amountIn
    ) public onlyOwner returns(bool) {
        uint bestPrice;
        uint worstPrice = type(uint).max;
        address bestRouter;
        address worstRouter;

        for(uint i = 0; i < routers.length(); i++) {
            uint amountOut = getAmountsOut(routers.at(i), token0, token1, amountIn);
            if(amountOut > bestPrice) {
                bestPrice = amountOut;
                bestRouter = routers.at(i);
            }
            if(amountOut < worstPrice) {
                worstPrice = amountOut;
                worstRouter = routers.at(i);
            }
        }

        if(bestPrice <= worstPrice) {
            return false;
        }

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

        return true;
    }

    function iteratePairList(uint start, uint n, uint amountIn) external onlyOwner {
        uint end = start + n;
        if(end > pairList.length) {
            end = pairList.length;
        }

        for(uint i = start; i < end; i++) {
            executeArbitrage(pairList[i].token0, pairList[i].token1, amountIn);
        }
    }

    function getAmountsOut(address router, address tokenIn, address tokenOut, uint amountIn) public view returns(uint) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint[] memory amounts = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
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
        pairList.push(TokenPair(token0, token1));
    }

    function clearPairList() external onlyOwner {
        delete pairList;
    }

    function withdrawTokens(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}