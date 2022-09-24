# Dynamic Storage

Dynamic storage is handled differently to fixed storage.

With dynamic storage, we have different behaviours, depending on what's being stored.

## Dynamic Arrays

Recall that a fixed array will occupy contiguous storage slots until we have space for all items in the array. 

So:

```js
uint64[4] arr; // will take up one slot
uint128[4] arr2; // will take up 2 slots
```

We can't do that with dynamic arrays, as we don't know how big they will end up being. Instead we start them at the **keccak256 hash of the storage slot**.

> Note: we store the *length* of the array at the storage slot.


```js
function getDynamicStorageAt(
    uint256 _orignalSlot,
    uint256 _offset
) external view returns (bytes32 result) {
    bytes32 slotHash = keccak256(abi.encodePacked(_orignalSlot));
    assembly {
        result := sload(add(slotHash, _offset))
    }
}
```

You can check this behaviour by running:

```sh
forge script RunArr
```


## Mappings

Mappings are non-contiguous, they are by definition hash maps.

We want to ensure the chance of a hash collision is practically zero, so we need to ensure separate mappings with identical keys point to different locations in memory. To that end, mappings work by:

- Taking the original storage *slot* of the mapping
- Hashing the key + the slot

Example:

```js
function readMappingStorageAt(uint256 _slot, uint256 _key) external view returns (bytes32 result) {
    bytes32 keyHash = keccak256(abi.encodePacked(_key, _slot));
    assembly {
        result := sload(keyHash)
    }
}
```

You can go deeper with this, for things like nested mappings, and for non-value types like arrays. I'm not going to do so here.

Check this with:

```sh
forge script RunMapping
```

## Strings

Strings are kinda funky, in theory they are dynamic arrays of characters. In practice they are implemented differently depending on the length of the string.

- If the string is 31 bytes or less, we can store string + size in a single slot, so we will:
    - The String is stored in the 1st 31 bytes (and padded with trailing 00s)
    - The size is stored in the final byte

- If the string is > 31 bytes, we can't fit it in a word with the size, so we revert to array storage:
    - Store the string as an array starting at the hash of the storage slot
    - Store the size of the string at the storage slto
