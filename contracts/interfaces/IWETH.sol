// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Wrapped Ether contract interface
 */
interface IWETH is IERC20 {
    /**
     * @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH token balance.
     */
    function deposit() external payable;

    /**
     * @dev Burn WETH token from caller account and withdraw matching ETH to the same.
     * @param wad Amount of WETH token to burn.
     */
    function withdraw(uint wad) external;
}
