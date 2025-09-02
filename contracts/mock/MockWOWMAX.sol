// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockWOWMAX contract
 * @notice Mock contract for WOWMAX swaps
 */
contract MockWOWMAX {
    mapping(address => uint256) private prices;
    mapping(address => uint256) private denominators;

    function setPrice(address token, uint256 priceUsd) external {
        prices[token] = priceUsd;
        uint256 decimals = ERC20(token).decimals();
        denominators[token] = 10 ** (18 + decimals);
    }

    function swap(address tokenIn, uint256 amountIn, address tokenOut) external returns (uint256[] memory amountsOut) {
        amountsOut = new uint256[](1);
        amountsOut[0] = amountIn * prices[tokenIn] * denominators[tokenOut] / prices[tokenOut] / denominators[tokenIn];
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountsOut[0]);
    }
}
