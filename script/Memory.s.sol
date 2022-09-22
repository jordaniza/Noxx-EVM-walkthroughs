// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "lib/forge-std/src/Script.sol";
import {Memory} from "../src/Memory.sol";

contract RunMemory is Script {
    function run() public {
        Memory _memory = new Memory();

        _memory.memoryLane();
    }
}