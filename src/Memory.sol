// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Memory {
    function memoryLane() public pure {
        bytes32[5] memory a;
        bytes32[2] memory b;
        b[0] = bytes32(uint256(1));
    }
}
