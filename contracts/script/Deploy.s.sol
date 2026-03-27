// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {CryptoVisionToken} from "../src/CryptoVisionToken.sol";
import {CryptoVisionSale} from "../src/CryptoVisionSale.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        CryptoVisionToken token = new CryptoVisionToken();
        console.log("CryptoVisionToken deployed at:", address(token));

        CryptoVisionSale sale = new CryptoVisionSale(address(token));
        console.log("CryptoVisionSale deployed at:", address(sale));

        // Transfer 1M CVT to sale contract
        token.transfer(address(sale), 1_000_000 * 10 ** token.decimals());
        console.log("Transferred 1,000,000 CVT to sale contract");

        vm.stopBroadcast();
    }
}
