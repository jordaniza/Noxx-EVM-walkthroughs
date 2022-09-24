// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@forge-std/Script.sol";
import "@forge-std/console.sol";

/// @notice the storage for the weth contract
contract WETHStorage {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    string public longString = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris auctor id augue a mollis. Ut vitae pulvinar nisl, id accumsan erat. Integer placerat at nisi eu faucibus. Nullam ac dui blandit eros tempus fringilla. Nam vitae bibendum lectus. Nullam et sem quis orci pharetra imperdiet. Suspendisse rutrum lectus neque, vitae porta est sollicitudin sit amet. Morbi non pharetra ligula. Fusce a pretium massa. Sed a arcu ac arcu feugiat laoreet in nec orci. Curabitur sollicitudin ipsum sit amet interdum venenatis. Duis diam quam, ultricies at consectetur ut, scelerisque ut lectus. Nulla vel suscipit augue, quis ultricies ex. Ut ac dignissim nisi, ac molestie tortor. Sed sagittis tortor lectus, at mattis ex malesuada vitae.Mauris finibus nisi leo, eget commodo arcu eleifend euismod. Duis sodales posuere ante, at ultrices lectus auctor a. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vestibulum sagittis, turpis at volutpat iaculis, eros turpis scelerisque purus, quis facilisis odio tellus ut orci. Suspendisse quis porttitor sem, eu tincidunt dui. Sed ultricies quam vulputate ante tincidunt vehicula. Nulla facilisi. Vivamus egestas tortor vitae molestie tempor. Morbi faucibus lobortis mi ac viverra. Fusce maximus scelerisque nunc, et molestie massa euismod ut. Fusce mollis vulputate iaculis. Cras vitae orci sed velit ultricies sollicitudin. Nunc suscipit vestibulum finibus.Phasellus sollicitudin dui tempor orci sollicitudin mollis. Nam iaculis libero volutpat rhoncus blandit. Duis rhoncus elit ex, non hendrerit neque pulvinar non. Ut arcu metus, blandit in semper vel, posuere vel lorem. Nam eu dolor iaculis, maximus erat nec, tempor mi. Curabitur ornare mattis posuere. Vestibulum quis augue imperdiet, luctus diam nec, consectetur lectus. Donec ac diam bibendum, egestas eros nec, euismod quam. Suspendisse bibendum aliquam diam. Nulla et neque sit amet turpis aliquet luctus a id nulla. Maecenas interdum nibh nec eros gravida viverra. Vivamus nec neque non lectus posuere mollis. Nulla faucibus viverra tellus, a scelerisque nisi condimentum vel. Aliquam erat volutpat.In aliquet, augue in laoreet cursus, libero orci ullamcorper risus, non tempor enim ligula nec ex. Nulla tincidunt semper consequat. Cras aliquam urna eu diam commodo tempor. Sed ut tempor urna. Sed tincidunt eros a urna hendrerit, sed porttitor massa dapibus. Maecenas placerat elit at malesuada blandit. Praesent faucibus convallis lorem, at lobortis metus maximus et.Nulla massa ex, tincidunt a nisi id, rhoncus iaculis sapien. Etiam blandit sollicitudin arcu, vitae cursus purus finibus aliquam. Donec in erat eget velit sodales ultricies sed sit amet leo. Praesent elementum pharetra ullamcorper. Vestibulum finibus, nisl non vestibulum faucibus, quam ligula mattis diam, sit amet fringilla dolor lacus ut diam. Donec rutrum ex nibh, quis imperdiet nunc consequat ac. Nam fringilla finibus rhoncus. Suspendisse turpis lorem, imperdiet at est eu, vulputate posuere sem. Etiam tempor sed mi et fringilla. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Morbi ac rhoncus eros, cursus bibendum leo. Nam quis ipsum et dolor congue pharetra sagittis at ipsum. Duis laoreet feugiat est at laoreet. Ut sed nulla nec lectus dictum tempus. Aliquam erat volutpat";

    string public _31chars = "123456789_123456789_123456789_1";
    
    // we cannot fit the whole string into one slot
    // so we store the string length in the slot
    // we store the string in the hash of the slot
    string public _32chars = "123456789_123456789_123456789_1";

    function getStorageAt(uint _slot) external view returns (bytes32 result) {
        assembly {
            result := sload(_slot)
        }
    }

    function getStorageDynamic(uint _slot, uint _offset) external view returns (bytes32 result) {
        bytes32 slotHash = keccak256(abi.encodePacked(_slot));
        assembly {
            result := sload(add(slotHash, _offset))
        }
    }
}

contract RunWeth is Script {
    function run() public {
        WETHStorage weth = new WETHStorage();

        bytes memory byteStringName = bytes(weth.name());
        bytes memory byteStringSymbol = bytes(weth.symbol());
        
        console.logBytes(byteStringName);
        console.logBytes(byteStringSymbol);

        uint stringLength = uint256(weth.getStorageAt(3));

        // convert string length to bytes by div 64 (2 hex chars = 1 byte)
        // we use +1 because we want to check the final storage location is 0x00          
        for (uint i; i < (stringLength / 64) + 1; i++) {
            console.logBytes32(weth.getStorageDynamic(3, i));
        }

        console.logBytes32(weth.getStorageAt(4));
        console.logBytes32(weth.getStorageAt(5));

    }
}
