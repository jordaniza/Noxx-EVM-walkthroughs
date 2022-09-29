# Slot Packing

When we pack storage slots, we need to store data in the same slot. How do we do that, mechanically?

## High level

Imagine we have 2 uint16s, these are 2 byte values and so can be represented each by 4 hex characters:

```
0xABAB1234
0xCDCD5678
```

In our 32 Byte word we therefore need the following:

```
0000 0000 0000 0000
0000 0000 0000 0000
0000 0000 0000 0000
CDCD 5678 ABAB 1234
```

What we know ahead of time, without knowing the data, is WHERE each data point is stored:

```
00000000 00000000
00000000 00000000
00000000 00000000
22222222 11111111 
```

We know this because the uints are 16bits (2 bytes), so will be packed next to each other.

Our aim, when inserting new data, is to:

- Establish where the data should be placed (based on its size)
- Zero out any data at that place in the word, but keep everything else
- Insert the new data at that slot

## In assembly

We can use bitmasks to achieve this:

```js
// Store the first value
PUSH4 0xAAAAAAAA
PUSH1 0x00 
SSTORE

// create a second 16 bit word
PUSH4 0xBBBBBBBB

// offset the word using exp and mul
PUSH1 0x04
PUSH2 0x100        // 1 byte
EXP                // offset by 4 * 1 byte 
MUL                // multiply the OG value

>>> Stack: bbbbbbbb 00000000
//         -------- --------
//           value   offset
```

