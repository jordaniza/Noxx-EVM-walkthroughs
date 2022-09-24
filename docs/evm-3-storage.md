# Storage

Storage differs from memory in that is a persistent, aribtrarily large key:value pairing. 

Whereas memory is a constantly growing bytearray navigated by offsets, storage addresses memory through pointers as 32 byte keys.

Each storage location is a storage slot, itself of 32 bytes.

> Note: "All values are initialised as 0 and zeros are not explicitly stored. This makes sense since 2^256 is approximately the number of atoms in the known, observable universe."

## Allocating Storage

Crucially, *each contract maintains its own storage*, which is pre-allocated at the point of contract creation. This means:

- All storage slot locations must be known when the contract is created.
- Dynamic storage pointers must be created when contrats are initialized (with negligible chance of over/underflow)
- *Storage slots cannot be created dynamically* (such as in function calls)

Storage slots are allocated when the contract is created, starting from slot 0. 

Examining the storage contract:

```js
contract Storage {
    uint256 slot1 = 0xff;
    uint256 slot2;
    uint256 slot3 = type(uint256).max;


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
```

Try running this with `forge script RunStorage`.

```js
  // 0xff as expected
  0x00000000000000000000000000000000000000000000000000000000000000ff
  
  // unitialized word
  0x0000000000000000000000000000000000000000000000000000000000000000
  
  // uint256 max value
  0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
  
  // implicit zero value
  0x0000000000000000000000000000000000000000000000000000000000000000

  // overflown value using assembly
  0x0000000000000000000000000000000000000000000000000000000000000000
```
## Exposing Storage to Other Contracts

Contracts control read and write access to their own storage BUT the actual data is publicly accessible. This means:

- All data is public, even for private variables, although it might be harder to access.
- Smart contracts cannot read from, or write to, other contracts' storage without having explicit getters or setters exposed to them.

# Storage in Assembly

`SSTORE` and `SLOAD` are relatively simple Opcodes:

- SSTORE(key, value):

```js
PUSH4 0xffffffff      // value to push to storage
PUSH1 0x00            // storage slot
SSTORE
```

- SLOAD(key)

## Storage Packing

The EVM will pack storage variables into the same word where it can. *This is not just in structs but in variable declartions too*, example:

```js
contract Storage {
    // ...
    uint128 slot4 = 0xab;
    uint128 slot5 = 0xbc;
}

console.logBytes32(_storage.readStorageAt(3));
>>> 0x000000000000000000000000000000bc000000000000000000000000000000ab
```
The above example shows storage packing of the 2 x 128 bit integers into the same storage variable.

## Loading Packed Storage Variables

> tl;dr unpacking storage variables requires additional operations that can often result in gas inefficiencies vs just storing each variable in a new word. Don't prematurely optimise.

We can unpack variables from storage by using a bitmask over the variable, knowing the size and location of the variable ahead of time. The article goes over this in more depth. I made paper notes on it a while back so will add them back to this document if I need them.


## StorageRoot in the account model

Each block in the Ethereum blockchain contains a StateRoot - the root of the merkle tree for that block.

The stateRoot contains a trie of all the ethereum accounts. Each account is identified by:
- Nonce (# transactions made by the account)
- Balance in Wei
- Code Hash (empty for EOAs)
- Storage Root

Storage root is itself a merkle root of the storage trie, and this is where we can find the contract storage that we have been discussing: 

```js
RPC_URL=https://rpc.ankr.com/eth
WETH=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

$ cast storage $WETH 0 --rpc-url $RPC_URL

0x57726170706564204574686572 000000000000000000000000000000000000 1a
----------------------------                                      --
  bytes("Wrapped Ether")                                        13 Bytes


// random EOA
$ cast storage 0x5a52e96bacdabb82fd05763e25335261b270efcb 0 --rpc-url https://rpc.ankr.com/eth
0x0000000000000000000000000000000000000000000000000000000000000000
```

So in the case of an EOA, I don't believe we would expect to see data in the storage slots.

# Understanding the Geth implementation

The canonical EVM client, Geth, is written in .go

SLOAD and SSTORE are implemented largely as you'd expect:

SSTORE:
- Pops the location, then value from the stack
- creates a new entry in the stateDB[address][location] = value
- Appends the new entry to the `journal`
- Attempts to write the state to storage permanently

The journal here allows for dirty reads: we can write state changes to the journal and then rollback state changes from the current transaction in the case of a revert.

SLOAD:
- Pops the location off the stack
- Grabs the value from memory, for that contract address
- Checks to see if there is a dirty value for that storage location, *and uses it if so*, else get the clean value
- Also, we check if there are any pending storage, and use if so.

>	**pendingStorage** - Storage entries that need to be flushed to disk, at the end of an entire block
>	**dirtyStorage** - Storage entries that have been modified in the current transaction execution

# References

[Storage in Depth](https://betterprogramming.pub/all-about-solidity-data-locations-part-i-storage-e50604bfc1ad)

[EVM deep Dive into storage](https://noxx.substack.com/p/evm-deep-dives-the-path-to-shadowy-3ea?utm_source=%2Fprofile%2F80455042-noxx&utm_medium=reader2&s=r)

[Geth implementation](https://noxx.substack.com/p/evm-deep-dives-the-path-to-shadowy-5a5?s=r)