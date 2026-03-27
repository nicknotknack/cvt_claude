# CryptoVision Token Sale

A decentralized token sale dApp where users can buy CVT (CryptoVision) tokens with ETH.

## Overview

- **Token**: CryptoVision (CVT), ERC-20, 11,000,000 total supply
- **Sale**: 1,000,000 CVT available at 0.0001 ETH per token (10,000 CVT / ETH)
- **Network**: Ethereum Sepolia Testnet

## Contracts (Sepolia)

| Contract | Address |
|----------|---------|
| CryptoVisionToken | `0x7475826c17026e4F758Ba7Ff7dF72b5Ddb4fc158` |
| CryptoVisionSale | `0x2e45775c7c359501063371aD1343474722FdE20a` |

## Tech Stack

**Contracts**
- Solidity 0.8.30
- OpenZeppelin v5 (ERC-20, Ownable2Step, ReentrancyGuard, SafeERC20)
- Foundry (forge, cast, anvil)

**Frontend**
- React + Vite + TypeScript
- wagmi v2 + viem
- RainbowKit
- Tailwind CSS

## Project Structure

```
CryptoVision/
├── contracts/
│   ├── src/
│   │   ├── CryptoVisionToken.sol
│   │   └── CryptoVisionSale.sol
│   ├── test/
│   │   └── CryptoVisionSale.t.sol
│   └── script/
│       └── Deploy.s.sol
└── frontend/
    └── src/
        ├── components/
        ├── hooks/
        ├── config/
        └── abi/
```

## Getting Started

### Contracts

```bash
cd contracts
forge install
forge build
forge test
```

Deploy to Sepolia:
```bash
forge script script/Deploy.s.sol --rpc-url sepolia --account <keystore> --broadcast
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## Security

- Checks-Effects-Interactions pattern on all state-changing functions
- ReentrancyGuard on ETH-receiving functions
- Ownable2Step for safe ownership transfers
- Custom errors for gas efficiency
