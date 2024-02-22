// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Yogi} from "../src/Yogi.sol";

contract YogiTest is Test {
    Yogi public yogi;

    function setUp() public {
        yogi = new Yogi("YogiCoin", "YOGI", 1000000000);
    }

}
