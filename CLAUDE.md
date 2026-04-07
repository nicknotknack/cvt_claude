# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CryptoVision is a token sale dApp where users connect their wallet and buy CVT tokens with ETH on Sepolia testnet. The repo has two independent workspaces: `contracts/` (Foundry/Solidity) and `frontend/` (React/Vite/TypeScript).

- **Token:** CryptoVision (CVT), ERC-20, 11M total supply (1M for sale, 10M team)
- **Price:** 0.0001 ETH per CVT (10,000 CVT per ETH)
- **Network:** Sepolia testnet (chainId 11155111)

## Commands

### Contracts (run from `contracts/`)

```bash
forge build                    # Compile contracts
forge test                     # Run all tests
forge test --match-test <name> # Run a single test
forge fmt                      # Format Solidity code
forge snapshot                 # Generate gas snapshots
```

Deploy to Sepolia:
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --account <keystore> --broadcast
```

### Frontend (run from `frontend/`)

```bash
npm run dev      # Start dev server
npm run build    # Type-check + build production bundle
npm run lint     # Run ESLint
npm run preview  # Preview production build
```

## Architecture

### Smart Contracts

Two contracts in `contracts/src/`:

**CryptoVisionToken.sol** — Standard OpenZeppelin ERC-20. Mints the entire 11M supply to the deployer on construction; no additional minting or burning.

**CryptoVisionSale.sol** — Holds 1M CVT tokens and sells them at a fixed rate. Inherits `Ownable2Step`, `ReentrancyGuard`. Key design points:
- ETH sent to `buyTokens()` or the `receive()` fallback are equivalent
- `endSale()` returns unsold tokens and all ETH to owner in one call
- `withdrawETH()` allows incremental ETH withdrawal without ending the sale
- Uses `SafeERC20` for all token transfers; custom errors for gas efficiency

Tests live in `contracts/test/CryptoVisionSale.t.sol` — 23 unit tests + 6 fuzz tests covering pricing math, supply exhaustion, access control, and ETH flows.

### Frontend

React 19 + Vite + TypeScript app. Provider stack in `App.tsx`: `WagmiProvider → QueryClientProvider → RainbowKitProvider`.

**Data flow:**
- `useSaleInfo()` (`hooks/useSaleInfo.ts`) — reads 4 contract view functions via `useReadContracts`, auto-refetches every 10s
- `useBuyTokens()` (`hooks/useBuyTokens.ts`) — wraps `useWriteContract` + `useWaitForTransactionReceipt` for the purchase flow

**Config:**
- `config/wagmi.ts` — wagmi config, Sepolia-only
- `config/contracts.ts` — hardcoded deployed addresses + imported ABIs from `abi/`

ABIs in `frontend/src/abi/` are manually maintained TypeScript files (not auto-generated at build time).

### Environment Variables

`contracts/.env` requires only `ETHERSCAN_API_KEY` (see `.env.example`). The frontend has no runtime env vars; network and contract addresses are hardcoded.

### Deployed Addresses (Sepolia)

```
Token:  0x7475826c17026e4F758Ba7Ff7dF72b5Ddb4fc158
Sale:   0x2e45775c7c359501063371aD1343474722FdE20a
```
