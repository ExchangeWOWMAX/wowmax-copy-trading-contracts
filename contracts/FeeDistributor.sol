// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FeeDistributor is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    mapping(address => uint256) public creditOf;      // withdrawable credit per recipient
    mapping(address => bool) public isFunder;         // allowed depositors managed by owner

    event Deposited(address indexed from, uint256 amount);
    event Allocated(address indexed wallet, uint256 amount, uint256 newBalance);
    event Withdrawn(address indexed wallet, uint256 amount);
    event FunderUpdated(address indexed funder, bool allowed);

    constructor(address tokenAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "FeeDistributor: token is zero");
        token = IERC20(tokenAddress);
        isFunder[msg.sender] = true; // owner is funder by default
        emit FunderUpdated(msg.sender, true);
    }

    /// @notice Owner can set or unset addresses allowed to deposit+allocate
    function setFunder(address funder, bool allowed) external onlyOwner {
        require(funder != address(0), "FeeDistributor: zero funder");
        isFunder[funder] = allowed;
        emit FunderUpdated(funder, allowed);
    }

    /// @notice Deposit tokens and allocate additive credits in one call
    /// @dev Caller must be allowed funder
    function deposit(
        address[] calldata recipientWallets,
        uint256[] calldata recipientAmounts,
        uint256 expectedTotal
    ) external whenNotPaused {
        require(isFunder[msg.sender], "FeeDistributor: not authorized");
        uint256 recipientsLength = recipientWallets.length;
        require(recipientsLength == recipientAmounts.length && recipientsLength > 0, "FeeDistributor: bad input");
        require(expectedTotal > 0, "FeeDistributor: zero total");

        // soft prechecks for clearer errors; SafeERC20 will still revert if something changes
        require(token.allowance(msg.sender, address(this)) >= expectedTotal, "FeeDistributor: insufficient allowance");
        require(token.balanceOf(msg.sender) >= expectedTotal, "FeeDistributor: insufficient balance");

        token.safeTransferFrom(msg.sender, address(this), expectedTotal);
        emit Deposited(msg.sender, expectedTotal);

        uint256 accumulatedTotal = 0;
        for (uint256 index = 0; index < recipientsLength;) {
            address recipient = recipientWallets[index];
            uint256 amount = recipientAmounts[index];

            require(recipient != address(0), "FeeDistributor: zero wallet");
            require(amount > 0, "FeeDistributor: zero amount");

            uint256 newBalance = creditOf[recipient] + amount;
            creditOf[recipient] = newBalance;
            emit Allocated(recipient, amount, newBalance);

            accumulatedTotal += amount;
            unchecked {++index;}
        }

        require(accumulatedTotal == expectedTotal, "FeeDistributor: sum mismatch");
    }

    /// @notice Recipient withdraws full credited balance only
    function withdrawAll() external whenNotPaused nonReentrant {
        uint256 amount = creditOf[msg.sender];
        require(amount > 0, "FeeDistributor: nothing to withdraw");

        creditOf[msg.sender] = 0;
        token.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Circuit breaker
    function pause() external onlyOwner {_pause();}

    function unpause() external onlyOwner {_unpause();}
}
