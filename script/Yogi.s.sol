// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import "../src/Yogi.sol";        // Adjust the path as necessary
import "forge-std/console2.sol";


contract DeployYogiToken is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("WALLET_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Yogi yogiCoin = new Yogi("YogiToken", "YOGI", 100000000 * 10**18);

        // Deploy YogiProxy with the implementation address
        console2.log("Total Supply:", yogiCoin.totalSupply());

        vm.stopBroadcast();
    }
}