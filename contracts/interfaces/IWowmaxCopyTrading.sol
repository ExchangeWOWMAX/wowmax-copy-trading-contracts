// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

/**
 * @title WOWMAX Copy Trading Interface
 * @notice Interface for the WOWMWAX Copy Trading, describes common data structures
 */
interface IWowmaxCopyTrading {

    /**
     * @notice Deposit Amount data structure
     * @param token Address of the token to be deposited
     * @param value Amount of the token to be deposited
     */
    struct DepositAmount {
        address token;
        uint256 value;
    }

    /**
     * @notice Token Price data structure
     * @param token Address of the token
     * @param price Price of the token in USD with 18 decimals
     * @param denominator Denominator of the price based on the token decimals
     */
    struct TokenPrice {
        address token;
        uint256 price;
        uint256 denominator;
    }

    /**
     * @notice Price Data structure
     * @param prices Array of token prices
     * @param deadline Deadline of the price data when it is considered expired in seconds
     * @param signature Signature of the price data
     */
    struct PriceData {
        TokenPrice[] prices;
        uint256 deadline;
        bytes signature;
    }

    /**
     * @notice Deposit data structure
     * @param to Address of the deposit receiver
     * @param leader Address of the leader
     * @param investmentTokenAddress Address of the investment token
     * @param investmentAmount Amount of the investment token
     * @param amounts Array of deposit amounts
     * @param priceData Price data of the deposit
     * @param referralCode Referral code for the deposit
     */
    struct Deposit {
        address to;
        address leader;
        address investmentToken;
        uint256 investmentAmount;
        DepositAmount[] amounts;
        PriceData priceData;
        bytes32 referralCode;
    }
}
