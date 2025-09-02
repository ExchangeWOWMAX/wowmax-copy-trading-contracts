// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "./IWowmaxCopyTrading.sol";

/**
 * @title Wowmax Copy Trading Funds Manager contract interface
 * @notice Interface for the Wowmax Copy Trading Funds Manager, describes the data structures
 * and functions that can be called from the copy trading funds manager
 */
interface IWowmaxCopyTradingFundsManager {

    error ErrInvalidRouterAddress();
    error ErrRouterAlreadyAdded(address router);
    error ErrRouterNotFound(address router);
    error ErrNotTradeSigner(address caller, address tradeSigner);
    error ErrInvalidWithdrawTokensLength(uint256 withdrawTokensLength, uint256 depositTokensLength);
    error ErrInvalidWithdrawToken(address withdrawToken, address depositToken);
    error ErrInvalidWithdrawAmount(address token, uint256 withdrawAmount, uint256 depositAmount);
    error ErrRouterNotAllowed(address router);
    error ErrDeadlineExpired();
    error ErrSwapFailed(address token);
    error ErrInsufficientOutputAmount(address token, uint256 amountOut, uint256 minAmountOut);
    error ErrZeroSwapNotAllowed(address token);

    /**
     * @notice Emitted when the trade signer address is updated
     * @param newTradeSigner New trade signer address
     * @param oldTradeSigner Old trade signer address
     */
    event TradeSignerUpdated(
        address newTradeSigner,
        address oldTradeSigner
    );

    /**
     * @notice Emitted when the router is added
     * @param router Address of the router that was added
     */
    event AllowedRouterAdded(
        address router
    );

    /**
     * @notice Emitted when the router is removed
     * @param router Address of the router that was removed
     */
    event AllowedRouterRemoved(
        address router
    );

    /**
     * @notice Swap data structure
     * @param amount Amount of the token to be swapped
     * @param token Address of the token to be swapped or received, depending on the swap direction
     * @param minAmountOut Minimum amount of the token to be received
     */
    struct Swap {
        uint256 amount;
        address token;
        uint256 minAmountOut;
        bytes swapData;
    }

    /**
     * @notice Multi-swap data structure
     * @param router Address of the router contract to perform the swap
     * @param token Address of the token to be swapped or received, depending on the swap direction
     * @param swaps Array of single swap data, that are executed in order
     * @param deadline Deadline of the multi-swap in seconds, after which the swap is considered expired
     */
    struct MultiSwap {
        address router;
        address token;
        Swap[] swaps;
        uint256 deadline;
    }

    /**
     * @notice Copies a trade from a leader against a followers' portfolio
     * @param multiSwap Multi-swap data
     * @param leader Leader address
     */
    function copyTrade(MultiSwap calldata multiSwap, address leader) external;

    /**
     * @notice Performs a multi-swap deposit
     * @param multiSwap Multi-swap data
     * @param leader Leader address
     * @param follower Follower address, who will receive the deposit
     * @param priceData Signed prices, used to verify the prices of the tokens in the deposit
     * @param referralCode Referral code for the deposit
     */
    function multiDeposit(MultiSwap calldata multiSwap, address leader, address follower, IWowmaxCopyTrading.PriceData calldata priceData, bytes32 referralCode) external;

    /**
     * @notice Performs a stable deposit
     * @param amount Amount of the stable token to be deposited
     * @param leader Leader address
     * @param follower Follower address, who will receive the deposit
     * @param priceData Signed prices, used to verify the prices of the tokens in the deposit
     * @param referralCode Referral code for the deposit
     */
    function stableDeposit(uint256 amount, address leader, address follower, IWowmaxCopyTrading.PriceData calldata priceData, bytes32 referralCode) external;


    /**
     * @notice Performs a multi-swap withdraw
     * @param multiSwap Multi-swap data
     * @param leader Leader address
     * @param to Recipient address
     * @return amountOut Total amount of outcome token received
     */
    function multiWithdraw(MultiSwap calldata multiSwap, address leader, address to) external returns (uint256 amountOut);
}
