// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title  CryptoVision Token
/// @notice ERC-20 token for the CryptoVision platform.
///         Total supply of 11,000,000 CVT is minted to the deployer at construction:
///         1,000,000 CVT is intended for the public sale and 10,000,000 CVT is retained
///         by the team.
/// @dev    Extends OpenZeppelin ERC20. No minting or burning after deployment.
contract CryptoVisionToken is ERC20 {
    /// @notice Deploys the token and mints the entire supply to the deployer.
    constructor() ERC20("CryptoVision", "CVT") {
        _mint(msg.sender, 11_000_000 * 10 ** decimals());
    }
}
