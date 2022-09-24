// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@forge-std/Script.sol";
import "@forge-std/console.sol";

contract Arr {
    uint256 i = 0xcb;

    uint256[] arr;

    // slot packing means this array will fit into a single storage slot
    uint32[4] arr2 = [22, 33, 44, 55];

    // this array is spread over 2 slots
    uint128[4] arr3 = [0xff, 0xaa, 0xbb, 0xcc];

    uint128[] arr5 = [1, 2, 3];

    function push(uint256 _item) external {
        arr.push(_item);
    }

    function pushToArr5() external {
        arr5.push(1);
    }

    function getArr() external view returns (uint256[] memory) {
        return arr;
    }

    function getStorageAt(uint256 _slot) external view returns (bytes32 result) {
        assembly {
            result := sload(_slot)
        }
    }

    // dynamic arrays store data starting at the hash of the storage slot
    // arrays are still contiguous, so we can step through the array by incrementing
    // the byte value by an offset
    function getDynamicStorageAt(uint256 _orignalSlot, uint256 _offset) external view returns (bytes32 result) {
        bytes32 slotHash = keccak256(abi.encodePacked(_orignalSlot));
        assembly {
            result := sload(add(slotHash, _offset))
        }
    }
}

contract RunArr is Script {
    function run() public {
        Arr arr = new Arr();

        // console.logBytes32(arr.getStorageAt(1));

        arr.push(0xffff);

        for (uint256 i; i < 100; i++) {
            arr.push(i);
        }

        console.logBytes32(arr.getStorageAt(1));

        console.logBytes32(arr.getStorageAt(2));


        // storage spread over 2 slots
        console.logBytes32(arr.getStorageAt(3));
        console.logBytes32(arr.getStorageAt(4));


        // length should increase from 3 to 4
        console.logBytes32(arr.getStorageAt(5));
        arr.pushToArr5();
        console.logBytes32(arr.getStorageAt(5));


        console.logBytes32(arr.getDynamicStorageAt(1, 0));

        console.logBytes32(arr.getDynamicStorageAt(5, 0));
        console.logBytes32(arr.getDynamicStorageAt(5, 1));
    }
}
