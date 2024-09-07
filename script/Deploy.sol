// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DACFactory} from "../src/DACFactory.sol";

contract DeployDACFactory is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with the account:", deployerAddress);

        vm.startBroadcast(deployerPrivateKey);

        DACFactory dacFactory = new DACFactory();

        vm.stopBroadcast();

        console.log("DAC Factory deployed to:", address(dacFactory));
    }
}
