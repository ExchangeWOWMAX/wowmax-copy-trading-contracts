// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {IWowmaxCopyTrading} from "./interfaces/IWowmaxCopyTrading.sol";

/**
 * @title Prices Verifier
 * @notice Verifies the prices of tokens in a deposit
 */
abstract contract PricesVerifier is EIP712Upgradeable {
    using ECDSA for bytes32;

    bytes32 private constant TOKEN_PRICE_TYPEHASH = keccak256(
        "TokenPrice(address token,uint256 price,uint256 denominator)"
    );

    bytes32 private constant PRICE_DATA_TYPEHASH = keccak256(
        "PriceData(TokenPrice[] prices,uint256 deadline)TokenPrice(address token,uint256 price,uint256 denominator)"
    );

    /**
     * @notice Initializes the contract
     */
    function __PricesVerifier_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init(name, version);
    }

    /**
     * @notice Verifies the prices of tokens in a deposit
     * @param priceData Price data to verify
     * @param expectedSigner Expected signer of the price data
     * @return true if the prices are verified, false otherwise
     */
    function verifyPrices(
        IWowmaxCopyTrading.PriceData calldata priceData,
        address expectedSigner
    ) public view returns (bool) {
        require(priceData.deadline >= block.timestamp, "PriceVerifier: expired deadline");
        require(priceData.deadline <= block.timestamp + 180, "PriceVerifier: incorrect deadline"); // 3 minutes buffer
        bytes32[] memory priceHashes = new bytes32[](priceData.prices.length);
        for (uint256 i = 0; i < priceData.prices.length; i++) {
            priceHashes[i] = keccak256(
                abi.encode(
                    TOKEN_PRICE_TYPEHASH,
                    priceData.prices[i].token,
                    priceData.prices[i].price,
                    priceData.prices[i].denominator
                )
            );
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PRICE_DATA_TYPEHASH,
                keccak256(abi.encodePacked(priceHashes)),
                priceData.deadline
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address recoveredSigner = ECDSA.recover(digest, priceData.signature);

        return recoveredSigner == expectedSigner;
    }
}
