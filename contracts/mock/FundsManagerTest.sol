// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "../WowmaxCopyTradingFundsManager.sol";

/**
 * @title FundsManagerTest
 * @notice Provides external access to swap functions for testing purposes
 */
contract FundsManagerTest is WowmaxCopyTradingFundsManager {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(address _vault, address _tradeSigner, address _stableCoin) WowmaxCopyTradingFundsManager(_vault, _tradeSigner, _stableCoin) {
    }

    function swapOneToMany(MultiSwap calldata multiSwap, address to) external nonReentrant returns (uint256 amountIn, uint256[] memory amountsOut) {
        require(to != address(0), "Funds Manager: invalid recipient");
        (amountIn, amountsOut) = _swapOneToMany(multiSwap);
        uint256 len = multiSwap.swaps.length;
        for (uint256 i = 0; i < len; i++) {
            IERC20(multiSwap.swaps[i].token).safeTransfer(to, amountsOut[i]);
        }
    }

    function swapManyToOne(MultiSwap calldata multiSwap, address to) external nonReentrant returns (uint256 amountOut) {
        require(to != address(0), "Funds Manager: invalid recipient");
        amountOut = _swapManyToOne(multiSwap, true);
        IERC20(multiSwap.token).safeTransfer(to, amountOut);
    }
}
