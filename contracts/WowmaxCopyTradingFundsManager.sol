// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IWowmaxCopyTradingFundsManager} from "./interfaces/IWowmaxCopyTradingFundsManager.sol";
import {IWowmaxCopyTradingVault} from "./interfaces/IWowmaxCopyTradingVault.sol";
import {IWowmaxCopyTrading} from "./interfaces/IWowmaxCopyTrading.sol";

/**
 * @title Wowmax Copy Trading Funds Manager State
 * @notice Manages the state for copy trading funds manager
 */
abstract contract WowmaxCopyTradingFundsManagerState {
    /**
     * @dev Vault contract
     */
    IWowmaxCopyTradingVault public vault;

    /**
     * @dev Trade signer address, authorized to copy trades
     */
    address internal tradeSigner;

    IERC20 public stableCoin;

    EnumerableSet.AddressSet internal allowedRouters;
}

/**
 * @title Wowmax Copy Trading Funds
 * @notice Manages the funds for copy trading
 */
contract WowmaxCopyTradingFundsManager is WowmaxCopyTradingFundsManagerState, ReentrancyGuard, Ownable2Step, IWowmaxCopyTradingFundsManager {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @param _vault Vault contract address
     * @param _tradeSigner Trade signer address
     * @param _stableCoin Stable coin contract address
     */
    constructor(address _vault, address _tradeSigner, address _stableCoin) Ownable(msg.sender) {
        vault = IWowmaxCopyTradingVault(_vault);
        tradeSigner = _tradeSigner;
        stableCoin = IERC20(_stableCoin);
    }

    /**
     * @dev Sets the trade signer address
     * @param _tradeSigner Trade signer address
     */
    function setTradeSignerAddress(address _tradeSigner) external onlyOwner {
        address oldTradeSigner = tradeSigner;
        tradeSigner = _tradeSigner;
        emit TradeSignerUpdated(_tradeSigner, oldTradeSigner);
    }

    function addAllowedRouter(address router) external onlyOwner {
        if (router == address(0)) {
            revert ErrInvalidRouterAddress();
        }
        if (!allowedRouters.add(router)) {
            revert ErrRouterAlreadyAdded(router);
        }
        emit AllowedRouterAdded(router);
    }

    function removeAllowedRouter(address router) external onlyOwner {
        if (!allowedRouters.remove(router)) {
            revert ErrRouterNotFound(router);
        }
        emit AllowedRouterRemoved(router);
    }

    /**
     * @inheritdoc IWowmaxCopyTradingFundsManager
     */
    function copyTrade(MultiSwap calldata multiSwap, address leader) external nonReentrant {
        if (msg.sender != tradeSigner) {
            revert ErrNotTradeSigner(msg.sender, tradeSigner);
        }
        uint256 len = multiSwap.swaps.length;
        address[] memory tokens = new address[](len);
        uint256[] memory amounts = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            tokens[i] = multiSwap.swaps[i].token;
            amounts[i] = multiSwap.swaps[i].amount;
        }
        uint256 balanceBefore = IERC20(multiSwap.token).balanceOf(address(this));
        vault.copyTradeWithdraw(leader, tokens, amounts);
        _swapManyToOne(multiSwap, false);
        uint256 amountOut = IERC20(multiSwap.token).balanceOf(address(this)) - balanceBefore;
        IERC20(multiSwap.token).safeTransfer(address(vault), amountOut);
        vault.copyTradeDeposit(leader, multiSwap.token, amountOut);
    }

    /**
     * @inheritdoc IWowmaxCopyTradingFundsManager
     */
    function multiDeposit(MultiSwap calldata multiSwap, address leader, address follower, IWowmaxCopyTrading.PriceData calldata priceData, bytes32 referralCode) external nonReentrant {
        (uint256 investmentAmount, uint256[] memory amountsOut) = _swapOneToMany(multiSwap);
        uint256 len = amountsOut.length;
        IWowmaxCopyTrading.DepositAmount[] memory amounts = new IWowmaxCopyTrading.DepositAmount[](len);
        for (uint256 i = 0; i < len; i++) {
            amounts[i] = IWowmaxCopyTrading.DepositAmount({
                token: multiSwap.swaps[i].token,
                value: amountsOut[i]
            });
            IERC20(multiSwap.swaps[i].token).safeIncreaseAllowance(address(vault), amountsOut[i]);
        }
        vault.makeDeposit(IWowmaxCopyTrading.Deposit({
            to: follower,
            leader: leader,
            investmentToken: multiSwap.token,
            investmentAmount: investmentAmount,
            amounts: amounts,
            priceData: priceData,
            referralCode: referralCode
        }));
    }

    /**
     * @inheritdoc IWowmaxCopyTradingFundsManager
     */
    function stableDeposit(uint256 amount, address leader, address follower, IWowmaxCopyTrading.PriceData calldata priceData, bytes32 referralCode) external nonReentrant {
        stableCoin.safeTransferFrom(msg.sender, address(this), amount);
        IWowmaxCopyTrading.DepositAmount[] memory amounts = new IWowmaxCopyTrading.DepositAmount[](1);
        amounts[0] = IWowmaxCopyTrading.DepositAmount({
            token: address(stableCoin),
            value: amount
        });
        stableCoin.safeIncreaseAllowance(address(vault), amount);
        vault.makeDeposit(IWowmaxCopyTrading.Deposit({
            to: follower,
            leader: leader,
            investmentToken: address(stableCoin),
            investmentAmount: amount,
            amounts: amounts,
            priceData: priceData,
            referralCode: referralCode
        }));
    }

    /**
     * @inheritdoc IWowmaxCopyTradingFundsManager
     */
    function multiWithdraw(MultiSwap calldata multiSwap, address leader, address to) external nonReentrant returns (uint256 amountOut) {
        uint256 balanceBefore = IERC20(multiSwap.token).balanceOf(address(this));
        (address[] memory tokens, uint256[] memory amounts) = vault.withdrawForSwap(leader, msg.sender);
        uint256 len = multiSwap.swaps.length;
        if (tokens.length != len) {
            revert ErrInvalidWithdrawTokensLength(len, tokens.length);
        }
        for (uint256 i = 0; i < len; i++) {
            if (tokens[i] != multiSwap.swaps[i].token) {
                revert ErrInvalidWithdrawToken(multiSwap.swaps[i].token, tokens[i]);
            }
            if (amounts[i] != multiSwap.swaps[i].amount) {
                revert ErrInvalidWithdrawAmount(tokens[i], multiSwap.swaps[i].amount, amounts[i]);
            }
        }
        uint256 balanceAfter = IERC20(multiSwap.token).balanceOf(address(this));
        amountOut = _swapManyToOne(multiSwap, true) + balanceAfter - balanceBefore;
        IERC20(multiSwap.token).safeTransfer(to, amountOut);
    }

    /**
     * @dev Swaps one token to many tokens
     * @param multiSwap Multi-swap data
     * @return amountIn Total amount of input tokens used
     * @return amountsOut Total amounts of outcome tokens received
     */
    function _swapOneToMany(MultiSwap calldata multiSwap) internal returns (uint256 amountIn, uint256[] memory amountsOut) {
        if (!allowedRouters.contains(multiSwap.router)) {
            revert ErrRouterNotAllowed(multiSwap.router);
        }
        if (multiSwap.deadline < block.timestamp) {
            revert ErrDeadlineExpired();
        }
        uint256 len = multiSwap.swaps.length;
        amountsOut = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            amountIn += multiSwap.swaps[i].amount;
        }
        IERC20(multiSwap.token).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(multiSwap.token).safeIncreaseAllowance(multiSwap.router, amountIn);
        uint256 balanceBefore;
        uint256 balanceAfter;
        for (uint256 i = 0; i < len; i++) {
            balanceBefore = IERC20(multiSwap.swaps[i].token).balanceOf(address(this));
            (bool success,) = multiSwap.router.call(multiSwap.swaps[i].swapData);
            if (!success) {
                revert ErrSwapFailed(multiSwap.swaps[i].token);
            }
            balanceAfter = IERC20(multiSwap.swaps[i].token).balanceOf(address(this));
            amountsOut[i] = balanceAfter - balanceBefore;
            if (amountsOut[i] < multiSwap.swaps[i].minAmountOut) {
                revert ErrInsufficientOutputAmount(multiSwap.swaps[i].token, amountsOut[i], multiSwap.swaps[i].minAmountOut);
            }
        }
    }

    /**
     * @dev Swaps many tokens to one token
     * @param multiSwap Multi-swap data
     * @return amountOut Total amount of outcome tokens received
     */
    function _swapManyToOne(MultiSwap calldata multiSwap, bool allowZeroSwaps) internal returns (uint256 amountOut) {
        if (!allowedRouters.contains(multiSwap.router)) {
            revert ErrRouterNotAllowed(multiSwap.router);
        }
        if (multiSwap.deadline < block.timestamp) {
            revert ErrDeadlineExpired();
        }
        uint256 amountIn;
        uint256 swapAmountOut;
        uint256 minAmountOut;
        address tokenIn;
        uint256 balanceBefore = IERC20(multiSwap.token).balanceOf(address(this));
        uint256 balanceAfter;
        uint256 len = multiSwap.swaps.length;
        for (uint256 i = 0; i < len; i++) {
            minAmountOut = multiSwap.swaps[i].minAmountOut;
            if (minAmountOut == 0) {
                if (!allowZeroSwaps) {
                    revert ErrZeroSwapNotAllowed(multiSwap.swaps[i].token);
                }
                continue;
            }
            amountIn = multiSwap.swaps[i].amount;
            tokenIn = multiSwap.swaps[i].token;
            if (tokenIn == multiSwap.token) {
                continue;
            }
            IERC20(tokenIn).safeIncreaseAllowance(multiSwap.router, amountIn);
            (bool success,) = multiSwap.router.call(multiSwap.swaps[i].swapData);
            if (!success) {
                revert ErrSwapFailed(tokenIn);
            }
            balanceAfter = IERC20(multiSwap.token).balanceOf(address(this));
            swapAmountOut = balanceAfter - balanceBefore;
            if (swapAmountOut < minAmountOut) {
                revert ErrInsufficientOutputAmount(tokenIn, swapAmountOut, minAmountOut);
            }
            balanceBefore = balanceAfter;
            amountOut += swapAmountOut;
        }
        return amountOut;
    }
}
