// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title  CryptoVision Token Sale
/// @notice Sells CVT tokens at a fixed rate of 10,000 CVT per 1 ETH.
///         The owner can withdraw accumulated ETH at any time and end the sale
///         to recover unsold tokens and remaining ETH.
/// @dev    Uses Ownable2Step for safer ownership transfers and ReentrancyGuard
///         on all ETH-receiving functions. Follows Checks-Effects-Interactions.
contract CryptoVisionSale is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // -------------------------------------------------------------------------
    // State
    // -------------------------------------------------------------------------

    /// @notice The CVT token being sold.
    IERC20 public immutable token;

    /// @notice Cumulative CVT (in wei) sold across all purchases.
    uint256 public totalTokensSold;

    /// @notice Whether the sale is currently accepting purchases.
    bool public saleActive = true;

    /// @notice Number of CVT tokens (in wei) issued per 1 ETH sent.
    uint256 public constant TOKENS_PER_ETH = 10_000;

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @dev Thrown when buyTokens is called while the sale is inactive.
    error SaleNotActive();

    /// @dev Thrown when buyTokens is called with zero ETH.
    error MustSendETH();

    /// @dev Thrown when the contract holds fewer tokens than the purchase requires.
    error InsufficientTokenSupply();

    /// @dev Thrown when withdrawETH is called with no ETH balance.
    error NoETHToWithdraw();

    /// @dev Thrown when a low-level ETH transfer fails.
    error ETHTransferFailed();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted on every successful token purchase.
    /// @param buyer       Address that sent ETH and received tokens.
    /// @param ethAmount   Amount of ETH sent (in wei).
    /// @param tokenAmount Amount of CVT received (in wei).
    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);

    /// @notice Emitted when the owner ends the sale.
    /// @param unsoldTokensReturned CVT balance returned to the owner (in wei).
    /// @param ethWithdrawn         ETH balance sent to the owner (in wei).
    event SaleEnded(uint256 unsoldTokensReturned, uint256 ethWithdrawn);

    /// @notice Emitted when the owner withdraws accumulated ETH mid-sale.
    /// @param amount ETH withdrawn (in wei).
    event ETHWithdrawn(uint256 amount);

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @notice Deploys the sale contract.
    /// @param _token Address of the CVT ERC-20 token contract.
    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    // -------------------------------------------------------------------------
    // External — purchase
    // -------------------------------------------------------------------------

    /// @notice Purchase CVT tokens by sending ETH.
    ///         Reverts if the sale is inactive, no ETH is sent, or the contract
    ///         does not hold enough tokens to fill the order.
    /// @dev    Follows Checks-Effects-Interactions. ReentrancyGuard prevents
    ///         reentrant calls via the token's transfer callback.
    function buyTokens() external payable nonReentrant {
        _executePurchase();
    }

    /// @notice Allows direct ETH transfers to trigger a token purchase.
    receive() external payable nonReentrant {
        _executePurchase();
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /// @dev Shared purchase logic used by buyTokens() and receive().
    function _executePurchase() internal {
        if (!saleActive) revert SaleNotActive();
        if (msg.value == 0) revert MustSendETH();

        uint256 tokenAmount = msg.value * TOKENS_PER_ETH;
        if (token.balanceOf(address(this)) < tokenAmount) revert InsufficientTokenSupply();

        // Effects before interactions (CEI)
        totalTokensSold += tokenAmount;

        token.safeTransfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    // -------------------------------------------------------------------------
    // External — views
    // -------------------------------------------------------------------------

    /// @notice Returns the number of CVT tokens (in wei) still held by this contract.
    /// @return remaining Current unsold token balance.
    function tokensRemaining() external view returns (uint256 remaining) {
        return token.balanceOf(address(this));
    }

    // -------------------------------------------------------------------------
    // External — owner
    // -------------------------------------------------------------------------

    /// @notice Ends the sale, returns all unsold CVT to the owner, and forwards
    ///         the full ETH balance to the owner.
    /// @dev    Sets saleActive to false first so no purchases can slip in.
    ///         Only callable by the owner.
    function endSale() external onlyOwner {
        saleActive = false;

        uint256 remainingTokens = token.balanceOf(address(this));
        if (remainingTokens > 0) {
            token.safeTransfer(owner(), remainingTokens);
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool sent,) = owner().call{value: ethBalance}("");
            if (!sent) revert ETHTransferFailed();
        }

        emit SaleEnded(remainingTokens, ethBalance);
    }

    /// @notice Withdraws the contract's full ETH balance to the owner.
    ///         The sale remains active after this call.
    /// @dev    Only callable by the owner.
    function withdrawETH() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        if (ethBalance == 0) revert NoETHToWithdraw();

        (bool sent,) = owner().call{value: ethBalance}("");
        if (!sent) revert ETHTransferFailed();

        emit ETHWithdrawn(ethBalance);
    }
}
