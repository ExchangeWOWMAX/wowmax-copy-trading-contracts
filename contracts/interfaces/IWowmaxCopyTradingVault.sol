// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "./IWowmaxCopyTrading.sol";
import {IWowmaxCopyTrading} from "./IWowmaxCopyTrading.sol";

/**
 * @title WOWMAX Copy Trading Vault interface
 * @notice Interface for the WOWMAX Copy Trading Vault
 */
interface IWowmaxCopyTradingVault is IWowmaxCopyTrading {

    error ErrNotFundsManager(address caller, address fundsManager);
    error ErrInvalidRange(uint256 from, uint256 to);
    error ErrRangeOutOfBounds(uint256 to, uint256 length);
    error ErrInvalidStableCoinAddress();
    error ErrInvalidWethAddress();
    error ErrInvalidPriceSignerAddress();
    error ErrNoAllowedTokensProvided();
    error ErrInvalidFundsManagerAddress();
    error ErrFeeIsTooHigh(uint256 fee, uint256 maxFee);
    error ErrInvalidLeaderAddress();
    error ErrInvalidPricesSignature();
    error ErrZeroDepositAmount(address token);
    error ErrNoSharesToWithdraw(address leader, address follower);
    error ErrTokenNotAllowed(address token);
    error ErrNotAllPricesDefined(address leader);
    error ErrInvalidTokenPriceOrder(address leader, address token);
    error ErrDepositTokenPriceNotDefined(address token);

    /**
     * @notice Emitted when a leader is added
     * @param leader Address of the added leader
     */
    event LeaderAdded(address indexed leader);

    /**
     * @notice Emitted when a leader is removed
     * @param leader Address of the removed leader
     */
    event LeaderRemoved(address indexed leader);

    /**
     * @notice Emitted when a follower deposits funds
     * @param leader Address of the leader
     * @param follower Address of the follower
     * @param nonce Current nonce of the leader
     * @param token Address of the deposit token
     * @param amount Amount of tokens deposited
     */
    event FollowerDeposit(
        address indexed leader,
        address indexed follower,
        uint256 nonce,
        address token,
        uint256 amount
    );

    /**
     * @notice Emitted when a follower withdraws funds
     * @param leader Address of the leader
     * @param follower Address of the follower
     * @param nonce Current nonce of the leader
     * @param token Address of the withdrawn token
     * @param amount Amount of tokens withdrawn
     */
    event FollowerWithdraw(
        address indexed leader,
        address indexed follower,
        uint256 nonce,
        address token,
        uint256 amount
    );

    /**
     * @notice Emitted when a token is sold as part of a copy trade operation.
     * @param leader The address of the leader
     * @param nonce Current nonce of the leader
     * @param token The address of the token being sold.
     * @param amount The amount of the token that was sold.
     */
    event CopyTradingSell(
        address indexed leader,
        uint256 nonce,
        address token,
        uint256 amount
    );

    /**
     * @notice Emitted when a token is bought as part of a copy trade operation.
     * @param leader The address of the leader
     * @param nonce Current nonce of the leader
     * @param token The address of the token that was bought.
     * @param amount The amount of the token that was bought.
     */
    event CopyTradingBuy(
        address indexed leader,
        uint256 nonce,
        address token,
        uint256 amount
    );

    /**
     * @notice Emitted when a follower's share is updated
     * @param leader Address of the leader
     * @param follower Address of the follower
     * @param share New share of the follower
     */
    event FollowerShareUpdate(
        address indexed leader,
        address indexed follower,
        uint256 share
    );

    /**
     * @notice Emitted when a leader's share is updated
     * @param leader Address of the leader
     * @param shares New share of the leader
     */
    event LeaderSharesUpdate(
        address indexed leader,
        uint256 shares
    );

    /**
     * @notice Emitted when a follower invests in a leader portfolio
     * @param leader Address of the leader
     * @param follower Address of the follower
     * @param token Address of the invested token
     * @param amount Amount of tokens invested
     * @param referralCode Referral code used for the investment
     */
    event Invest(
        address indexed leader,
        address indexed follower,
        address token,
        uint256 amount,
        bytes32 referralCode
    );

    /**
     * @notice Emitted when a fee is withdrawn
     * @param leader Address of the leader
     * @param token Address of the withdrawn token
     * @param amount Amount of tokens withdrawn
     */
    event FeeWithdraw(
        address indexed leader,
        address token,
        uint256 amount
    );

    /**
     * @notice Emitted when the fee is updated
     * @param newFee New fee value
     * @param oldFee Old fee value
     */
    event FeeUpdated(
        uint256 newFee,
        uint256 oldFee
    );

    /**
     * @notice Emitted when the price signer is updated
     * @param newSigner New price signer address
     * @param oldSigner Old price signer address
     */
    event PriceSignerUpdated(
        address newSigner,
        address oldSigner
    );

    /**
     * @notice Emitted when the funds manager is updated
     * @param newFundsManager New funds manager address
     * @param oldFundsManager Old funds manager address
     */
    event FundsManagerUpdated(
        address newFundsManager,
        address oldFundsManager
    );

    /**
     * @notice Emitted when a token is allowed for copy trading
     * @param token Address of the allowed token
     */
    event TokenAllowed(
        address token
    );

    /**
     * @notice Emitted when a token is disallowed for copy trading
     * @param token Address of the disallowed token
     */
    event TokenDisallowed(
        address token
    );

    /**
     * @notice Withdraws follower's funds for swap to one token
     * follower is determined by the transaction origin
     * @param leader Leader address
     * @param follower Follower address
     * @return tokens Array of token addresses to be withdrawn
     * @return amounts Array of token amounts to be withdrawn
     */
    function withdrawForSwap(address leader, address follower) external returns (address[] memory tokens, uint256[] memory amounts);

    /**
     * @notice Withdraws followers' funds for copy trade
     * @param leader Leader address
     * @param tokens Array of token addresses to be withdrawn
     * @param amounts Array of token amounts to be withdrawn
     */
    function copyTradeWithdraw(address leader, address[] memory tokens, uint256[] memory amounts) external;

    /**
     * @notice Deposits followers' funds for copy trade
     * @param leader Leader address
     * @param token Address of the token to be deposited
     * @param amount Amount of the token to be deposited
     */
    function copyTradeDeposit(address leader, address token, uint256 amount) external;

    /**
     * @notice Makes a deposit
     * @param deposit Deposit data
     */
    function makeDeposit(Deposit calldata deposit) external;
}
