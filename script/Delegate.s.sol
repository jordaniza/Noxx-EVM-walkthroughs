// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@forge-std/Script.sol";
import "@forge-std/console.sol";

abstract contract StrUpdate {
    string public str;

    function sayHello() external view returns (string memory) {
        return string.concat(str, " Hello");
    }

    function setStr(string calldata _newStr) external {
        str = _newStr;
    }
}

contract Base is StrUpdate {
    constructor() {
        str = "Base";
    }
}

contract Delegate is StrUpdate {
    constructor() {
        str = "Delegate";
    }

    function delegateHello(address _base) external returns (string memory) {
        (bool success2, bytes memory data) = _base.delegatecall(abi.encodeWithSelector(StrUpdate.sayHello.selector));
        require(success2, "Call failed");
        return string(data);
    }
}

contract Uninitialized {
    // we can update the execution context for the duration of the transaction
    function delegateHello(address _base) external returns (string memory) {
        (bool success,) = _base.delegatecall(abi.encodeWithSelector(StrUpdate.setStr.selector, "Uninitialized"));
        require(success, "transaction failed");
        (bool success2, bytes memory data) = _base.delegatecall(abi.encodeWithSelector(StrUpdate.sayHello.selector));
        require(success2, "Call failed");
        return string(data);
    }
}

contract StorageSlotCollisionBase {
    bool public isAuthorized = false;

    function checkIsAuth() external view returns (bool) {
        return isAuthorized;
    }
}

// isAuthorized is not sourced by name. It is sourced by storage slot.
// boolean coercing of 1 == true, your auth check is now broken
contract StorageSlotCollisionRekt {
    uint256 slot0 = 1;
    bool public isAuthorized = false;

    function delegateAuth(address _base) external returns (bytes memory, bool) {
        (bool success, bytes memory data) =
            _base.delegatecall(abi.encodeWithSelector(StorageSlotCollisionBase.checkIsAuth.selector));
        require(success, "Call failed");
        return (data, abi.decode(data, (bool)));
    }
}

// correct use of delegate call respects the storage slot ordering
// this is the basis of upgradeable smart contracts
contract StorageSlotCollisionBigBrain {
    bool public isAuthorized = false;
    uint256 slot1 = 1;

    function delegateAuth(address _base) external returns (bytes memory, bool) {
        (bool success, bytes memory data) =
            _base.delegatecall(abi.encodeWithSelector(StorageSlotCollisionBase.checkIsAuth.selector));
        require(success, "Call failed");
        return (data, abi.decode(data, (bool)));
    }
}

contract RunDelegate is Script {
    function run() public {
        Base base = new Base();
        Delegate delegate = new Delegate();
        Uninitialized u = new Uninitialized();
        StorageSlotCollisionBase sscBase = new StorageSlotCollisionBase();
        StorageSlotCollisionRekt sscRekt = new StorageSlotCollisionRekt();
        StorageSlotCollisionBigBrain sscBB = new StorageSlotCollisionBigBrain();

        console.log(base.sayHello());
        console.log(delegate.delegateHello(address(base)));
        console.log(u.delegateHello(address(base)));

        (bytes memory dataRekt, bool authRekt) = sscRekt.delegateAuth(address(sscBase));
        bool isAuth = sscBase.isAuthorized();

        (bytes memory dataBB, bool authBB) = sscBB.delegateAuth(address(sscBase));

        console.logBytes(dataRekt);
        console.logBytes(dataBB);
        console.log("base auth", isAuth);
        console.log("delegateAuthRekt", authRekt);
        console.log("delegateAuthBB", authBB);

        // this returns success, although no code is executed!
        (bool addrSuccess,) = address(0xBeef)
            .delegatecall(
                abi.encodeWithSignature("someFunctionIWantToCall()")
            );
        console.log(addrSuccess);
    }
}
