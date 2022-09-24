// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@forge-std/Script.sol";
import "@forge-std/console.sol";

contract Storage {
    uint256 slot1 = 0xff;
    uint256 slot2;
    uint256 slot3 = type(uint256).max;

    uint128 slot4 = 0xab;
    uint128 slot5 = 0xbc;

    function readStorageAt(uint256 _slot) external view returns (bytes32 result) {
        assembly {
            result := sload(_slot)
        }
    }

    function overflowStorageSlot() external view returns (bytes32 result) {
        assembly {
            result := add(1, sload(2))
        }
    }
}

contract RunStorage is Script {
    function run() public {
        Storage _storage = new Storage();
        console.logBytes32(_storage.readStorageAt(0));
        console.logBytes32(_storage.readStorageAt(1));
        console.logBytes32(_storage.readStorageAt(2));
        console.logBytes32(_storage.readStorageAt(3));

        console.logBytes32(_storage.overflowStorageSlot());
    }
}
