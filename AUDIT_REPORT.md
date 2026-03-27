# CryptoVision Security Audit Report

**Date:** 2026-03-26
**Auditor:** Smart Contract Security Audit (Automated)
**Scope:** CryptoVisionToken.sol, CryptoVisionSale.sol, CryptoVisionSale.t.sol
**Solidity Version:** ^0.8.24
**Framework:** Foundry

---

## Summary

CryptoVision is a straightforward fixed-price ERC-20 token sale. The codebase is small and uses well-established OpenZeppelin libraries. No critical vulnerabilities were found. Several medium and low severity issues are documented below.

| Severity      | Count |
|---------------|-------|
| Critical      | 0     |
| High          | 1     |
| Medium        | 2     |
| Low           | 3     |
| Informational | 4     |

---

## Findings

### [H-1] Reentrancy in `buyTokens()` -- State Update After External Call

**Severity:** High
**Location:** `CryptoVisionSale.sol`, lines 27-28

**Description:**
The `buyTokens()` function calls `token.transfer(msg.sender, tokenAmount)` on line 27 before updating `totalTokensSold` on line 28. This violates the Checks-Effects-Interactions (CEI) pattern. If the token contract were malicious or had hooks (e.g., ERC-777 tokens), a reentrant call could exploit the stale state.

In practice, since `CryptoVisionToken` is a standard OpenZeppelin ERC-20 with no hooks or callbacks, and the token address is set at construction and cannot change, the actual exploitability is very low. However, the balance check on line 25 (`token.balanceOf(address(this)) >= tokenAmount`) would still correctly gate reentrancy since the balance decreases after each transfer. The `totalTokensSold` counter could become inaccurate if reentrancy were possible, but the supply cannot be drained beyond what the contract holds.

Despite the low practical risk, this is a high-severity pattern violation because:
- It sets a bad precedent.
- If the token were ever swapped for an ERC-777 or hook-bearing token, this would become exploitable.
- The fix is trivial.

**Recommendation:**
Move the state update before the external call:
```solidity
totalTokensSold += tokenAmount;
token.transfer(msg.sender, tokenAmount);
```
Alternatively, add OpenZeppelin's `ReentrancyGuard` with the `nonReentrant` modifier.

---

### [M-1] Unchecked Return Value of `token.transfer()` in `buyTokens()`

**Severity:** Medium
**Location:** `CryptoVisionSale.sol`, lines 27 and 46

**Description:**
The return value of `token.transfer()` is not checked. The `IERC20.transfer()` function returns a `bool` indicating success or failure. While OpenZeppelin's ERC-20 implementation reverts on failure (making the return value always `true` on success), this is not guaranteed by the ERC-20 standard. Some non-standard tokens return `false` instead of reverting.

Since `CryptoVisionToken` uses OpenZeppelin's ERC-20, this is safe in the current deployment. However, if the sale contract were ever reused with a different token, unchecked returns could lead to tokens not being transferred while the contract still accepts ETH.

**Recommendation:**
Use OpenZeppelin's `SafeERC20` library:
```solidity
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
using SafeERC20 for IERC20;

// Then use:
token.safeTransfer(msg.sender, tokenAmount);
```

---

### [M-2] `endSale()` Can Be Permanently Bricked if Owner is a Contract That Rejects ETH

**Severity:** Medium
**Location:** `CryptoVisionSale.sol`, lines 49-53

**Description:**
In `endSale()`, the ETH transfer to the owner uses a low-level `.call{value: ...}("")` which is correct. However, if the transfer fails (e.g., owner is a contract without a `receive` function), the entire `endSale()` transaction reverts. This means the sale can never be ended, and unsold tokens can never be recovered via this function.

The `withdrawETH()` function has the same issue but is less critical since `endSale()` also handles token recovery.

Note: If the owner is an EOA (externally owned account), this is not an issue. The deployer being an EOA is the expected deployment scenario.

**Recommendation:**
Consider using a pull pattern where ETH is accumulated and the owner claims it separately, or separate the token return and ETH withdrawal in `endSale()` so that a failing ETH transfer does not block token recovery:
```solidity
function endSale() external onlyOwner {
    saleActive = false;
    uint256 remainingTokens = token.balanceOf(address(this));
    if (remainingTokens > 0) {
        token.transfer(owner(), remainingTokens);
    }
    // ETH withdrawal handled separately via withdrawETH()
}
```

---

### [L-1] No Event Emitted for `endSale()` and `withdrawETH()`

**Severity:** Low
**Location:** `CryptoVisionSale.sol`, lines 41-54 and 56-62

**Description:**
Neither `endSale()` nor `withdrawETH()` emit events. This makes it harder to track administrative actions off-chain and reduces transparency for users monitoring the sale.

**Recommendation:**
Add events:
```solidity
event SaleEnded(uint256 tokensReturned, uint256 ethWithdrawn);
event ETHWithdrawn(uint256 amount);
```

---

### [L-2] No Maximum Purchase Limit / No Allowlist

**Severity:** Low
**Location:** `CryptoVisionSale.sol`, `buyTokens()`

**Description:**
Any address can buy any amount of tokens up to the entire supply in a single transaction. A single whale could purchase all 1M tokens for sale in one transaction (100 ETH), leaving nothing for other participants.

**Recommendation:**
If broader distribution is desired, consider adding a per-address cap:
```solidity
mapping(address => uint256) public purchased;
uint256 public constant MAX_PER_ADDRESS = 50_000 * 10**18;
```
This is a design decision, not a bug -- noted for awareness.

---

### [L-3] `endSale()` is One-Way -- Sale Cannot Be Restarted

**Severity:** Low
**Location:** `CryptoVisionSale.sol`, line 42

**Description:**
Once `endSale()` is called, `saleActive` is set to `false` and there is no function to reactivate it. Additionally, `endSale()` transfers all remaining tokens back to the owner, so even if the flag were toggled, the contract would have no tokens to sell.

This is likely intentional for a simple sale, but worth noting that if the owner accidentally calls `endSale()`, the sale cannot be resumed without redeploying.

**Recommendation:**
Consider adding a `pauseSale()` / `resumeSale()` pair if operational flexibility is needed, or accept this as intended behavior.

---

### [I-1] `totalTokensSold` is Redundant

**Severity:** Informational
**Location:** `CryptoVisionSale.sol`, line 9

**Description:**
`totalTokensSold` tracks cumulative sales but is never used internally for any logic. It can be derived off-chain from `TokensPurchased` events or calculated as `initialBalance - tokensRemaining()`. Storing it on-chain costs extra gas per purchase (~5,000 gas for the SSTORE).

**Recommendation:**
Remove if gas optimization is a priority, or keep for convenience -- it is a minor cost.

---

### [I-2] Token Address is Immutable but Not Declared `immutable`

**Severity:** Informational
**Location:** `CryptoVisionSale.sol`, line 8

**Description:**
The `token` state variable is set once in the constructor and never modified. Declaring it as `immutable` would save gas on every read (~2,100 gas saved per SLOAD replaced with PUSH).

**Recommendation:**
```solidity
IERC20 public immutable token;
```

---

### [I-3] No Zero-Address Check in Constructor

**Severity:** Informational
**Location:** `CryptoVisionSale.sol`, line 17

**Description:**
The constructor does not validate that `_token` is not the zero address. Deploying with `address(0)` would result in a non-functional sale contract.

**Recommendation:**
```solidity
require(_token != address(0), "Token address cannot be zero");
```

---

### [I-4] Missing Test Scenarios

**Severity:** Informational
**Location:** `CryptoVisionSale.t.sol`

**Description:**
The test suite is solid for core functionality but is missing coverage for:

1. **Buying the exact remaining supply** -- edge case where `tokenAmount` exactly equals `balanceOf(address(this))`.
2. **`endSale()` with zero ETH balance** -- calling `endSale()` when no purchases have been made (only tokens to return, no ETH).
3. **`endSale()` with zero token balance** -- calling `endSale()` when all tokens have been sold (only ETH to return, no tokens).
4. **Fuzz testing** -- no fuzz tests for `buyTokens()` with varying ETH amounts.
5. **Overflow edge case** -- sending a very large `msg.value` that causes `msg.value * TOKENS_PER_ETH` to overflow (though Solidity 0.8.24 would revert, it is good to test this explicitly).
6. **Reentrancy test** -- no test demonstrating that reentrancy is not exploitable.
7. **Ownership transfer** -- no test for `transferOwnership()` inherited from Ownable and its effect on `endSale()`/`withdrawETH()`.

**Recommendation:**
Add the above test cases for more complete coverage.

---

## Front-Running / MEV Analysis

**Risk:** Low

The sale uses a fixed price (10,000 CVT per ETH) with no bonding curve or dynamic pricing. Front-running a purchase provides no advantage since the price does not change based on order. The only MEV scenario is a race to buy the last tokens when supply is nearly exhausted, which is an inherent property of any first-come-first-served sale and not a vulnerability.

---

## Denial of Service Analysis

**Risk:** Low

- The owner can end the sale at any time via `endSale()`, which is expected admin behavior.
- No external party can brick the contract. The only DoS vector is M-2 (owner being a contract that rejects ETH), which is self-inflicted.
- The `require` on supply in `buyTokens()` correctly prevents purchases when tokens run out rather than silently failing.

---

## Overall Assessment

The CryptoVision contracts are simple, well-structured, and appropriate for a basic fixed-price token sale on a testnet. The use of OpenZeppelin's ERC-20 and Ownable is a good practice. The codebase has no critical vulnerabilities.

**Key actions recommended before mainnet deployment:**

1. **Fix H-1**: Reorder state updates before external calls in `buyTokens()` (CEI pattern).
2. **Fix M-1**: Use `SafeERC20` for all token transfers.
3. **Fix I-2**: Mark `token` as `immutable` for gas savings.
4. **Expand test coverage** per I-4 recommendations.

The remaining findings (M-2, L-1 through L-3, I-1, I-3) are improvements worth considering but are not blockers for a testnet deployment.
