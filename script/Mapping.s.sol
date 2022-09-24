// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@forge-std/Script.sol";
import "@forge-std/console.sol";

contract Mapping {
    mapping(uint256 => address) mp;
    mapping(uint256 => address) mp1;

    constructor() {
        mp[0xAA] = address(0xBeef);
        mp1[0xBB] = address(0xC0FFEE);

    }

    function readStorageAt(uint256 _slot) external view returns (bytes32 result) {
        assembly {
            result := sload(_slot)
        }
    }

    function readMappingStorageAt(uint256 _slot, uint256 _key) external view returns (bytes32 result) {
        bytes32 keyHash = keccak256(abi.encodePacked(_key, _slot));
        assembly {
            result := sload(keyHash)
        }
    }
}

contract RunMapping is Script {
    function run() public {
        Mapping _mapping = new Mapping();

        console.logBytes32(_mapping.readStorageAt(0));
        console.logBytes32(_mapping.readMappingStorageAt(0, 0xAA));

        console.logBytes32(_mapping.readMappingStorageAt(1, 0xBB));

    }
}
