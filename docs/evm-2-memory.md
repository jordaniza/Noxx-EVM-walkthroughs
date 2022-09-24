# Memory in the EVM

Data in the EVM passes between Memory, the Stack, Calldata and Storage. 

Memory itself is a bytearray that is always read in 32 byte chunks (but you can offset)

Note: 

* Data can be *stored* in memory in either 32 byte or 1 byte chunks
* The bytearray increases in 32 Byte chunks, meaning that even writing 1 Byte may require a new 32 byte array to be added (in which case the data will be padded with zeros)
* You *can* however, write to existing 32 byte words with new data, as long as offset + datasize is < existing data length (using MSTORE8 below)

## Opcodes

We have 3 opcodes for memory:

```js
MSTORE(OFFSET, VALUE)   // Store 32B/256b VALUE starting from location OFFSET 
MLOAD(OFFSET)           // Load 32B value starting from location OFFSET (can start from anywhere)
MSTORE8(OFFSET, VALUE)  // Store 1B/8b VALUE starting from location OFFSET - starting from least significant bytes (LEFT!)
```
Consider then:


```js
604260005260206000F3 

PUSH 42           
PUSH 00            
MSTORE(00, 0x42)   // store the value 0x42 at 00 in memory, occupying 32 bytes total
PUSH 20             
PUSH 00
RETURN(00, 20)     // return the first 0x20 = 32 bytes of memory
>>> 0x42           // 66 in decimal
```

Note that we could amend this ever so slightly:
```js
60426000 53 60206000F3

PUSH 42           
PUSH 00            
MSTORE8(00, 0x42)   // store the value 0x42 at 00 in memory, occupying 1 byte (on the left, fill the rest)
PUSH 20             
PUSH 00
RETURN(00, 20)     // return the first 0x20 = 32 bytes of memory
>>> 0x42..00       // 2.985265e+76 in decimal
```
So storing an 8 bit vs 32 bit *COMPLETELY* changes the value stored


Try this: 60426000536022600153

If we loaded MSTORE8 at OFFSET 0, the first time we would create a new 32 Byte word:

```
4200 0000 0000 0000 
0000 0000 0000 0000
0000 0000 0000 0000
0000 0000 0000 0000
```

We can then load a second piece of data (22) at offset 01

```
4222 0000 0000 0000
0000 0000 0000 0000
0000 0000 0000 0000
0000 0000 0000 0000
```

You could even go a step further and load from memory from the first offset:

6042600053602260015360015160f81c

```js
PUSH1 0x42
PUSH1 0x00
MSTORE8
PUSH1 0x22
PUSH1 0x01
MSTORE8
PUSH1 0x01
MLOAD
>>> 0x2200000000000000000000000000000000000000000000000000000000000000 // stack
PUSH1 0xf8    // 248 = 31 bytes
SHR           // trim the stack
>>> 0x22
```
So we have stored 0x22 as 1 byte in memory, then read the full 32 byte word, then got back to 1 byte.

# Solidity Memory Basics

**You just gotta know this:** Solidity has 3 reserved spaces in memory:

- 0x00 - 0x3f (64B): Scratch Space (used for internal methods like hashing)
- 0x40 - 0x5f (32B): Free Memory Pointer (see below)
- 0x60 - 0x7f (32B): Zero slot

> The zero slot is used as initial value for dynamic memory arrays and should never be written to (the free memory pointer points to 0x80 initially).

Basically dynamic arrays load their state from the zero slot. A little quirk here is that some operations may require more than 64 Bytes of scratch, in which case the compiler will:
1. Grab the FMP to find where the next byte of free memory starts
2. Write scratch to memory past the FMP

Noting that memory is *never freed in solidity* until execution is complete, this means that *we cannot assume values past the FMP are zeroed*

## FMP

The FMP is literally just that, a pointer to a 256 bit memory address where there is no data currently being used in memory.

This means that you'll see this pattern a lot:

```
60 80 = PUSH(0x80) 
60 40 = PUSH(0x40)
52 = MLOAD(0x40, 0x80)
```

Load into memory the value 0x80 at a 0x40 offset. Noting that:
0x40 is the start of the FMP
0x80 is the *current* FMP - indicating free memory starts at 0x80 (after 0x7f, end of the zero slot)


Noxx's memory lane contract is loaded in the `src` folder, we can run it with `forge debug RunMemory` The simplified version is as follows:

```js
PUSH1(0x80)
PUSH1(0x40)
MSTORE(0x40 0x80)

// free memory begins at 0x80, our memory now looks like
0000 0000 0000 0000 0000 0000 0000 0000  // scratch  
0000 0000 0000 0000 0000 0000 0000 0000  // scratch
0000 0000 0000 0000 0000 0000 0000 0000  // scratch
0000 0000 0000 0000 0000 0000 0000 0000  // scratch 
0000 0000 0000 0000 0000 0000 0000 0000  // FMP
0000 0000 0000 0000 0000 0000 0000 0080  // FMP
```

> Note: 1 byte is 2 hex character, so 2 rows above is 32 bytes

Above shows (4 x 32) hex character for scratch = (4 x 32) / 2 = 64 bytes
Then        (2 x 32) hex           for FMP     = (2 x 32) / 2 = 32 bytes 

## Allocating Memory for our bytes32[5] array

So this is basic initialisation. All good in the hood. Next we need to load the following line

```js
bytes32[5] memory a;
```

What we will need then is 5 x 32 bytes = 160 bytes (0xa0) of additional space to be allocated in memory for a bytes32 array of length 5. When added to the current value of FMP (0x80) we get:

0x80 + 0xa0 = 0x120
(or 288 in decimal)

The code looks like
```js
PUSH1(0x40)        // push the offset to the stack 
MLOAD(0x40)        // load the offset in Memory (0x40 = 64 bytes, so ignore scratch)
>>> Stack: 80      // start of free memory
DUP(0x80)          // copy the location of free memory
PUSH1(0xa0)        // push 32 x 5 = a0 to stack 
ADD(0xa0 0x80)     // free memory location + additional memory needed for bytes32[5]
>>> Stack: 120 80
PUSH1(0x40)        // push offset to ignore scratch
MSTORE(0x40, 120)  // overwrite the FMP with the new location of free memory!
```
so we've just replaced 0....80 with 0...120.

## Initializing the empty array in memory

We've been able to *allocate* 0xa0 bytes of free memory to hold the array, but as of yet we haven't actually initialized the array. 

> Remember that arrays are zero initialized in solidity.

There are obviously many methods to create zero variables, in this case, we are using [`CALLDATACOPY`](https://www.ethervm.io/#37), which takes

```py
    memory[destOffset:destOffset+length] = msg.data[offset:offset+length]
```

1. destOffset - offset *in memory* to copy *to*
2. offset - offset *in calldata* to copy *from*
3. length - how long to copy

```js
>>> Stack: a0 a0 80
CALLDATASIZE(0x00)       // Empty calldata, push 0 to stack
DUP4
>>> Stack: 80 0 a0 a0   
CALLDATACOPY(0x80 0x00 0xa0)
```

So here, we are copying:

1. Into the current FMP = 0x80 
2. From the start of calldata = 0x00
3. 160 bytes = 5 * 32 bytes = 0xa0

> Calldata is empty so the offset:offset+length is assumed (by me) to be zeroed out

Our memory now looks like this:

`000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000`

Running some checks:

```py
str = {copy above}
len(str)
>>> 576                               # recall 2 character in hex == 1 byte
len(str) / 2
>>> 288                               # 288 bytes
EoFMP = str.find('120') + len('120')  # find start of FMP address + add length of address
EoFMP
>>> 192                               # end of the FMP reserved slot
EoFMP + 64                            # End of FMP + Zero slot (32 bytes = 64 hexchars)  
>>> 256                               # 128 bytes
len(str) - (EoFMP + 64)
>>> 320
hex(int(320 / 2))                     
>>> 0xa0                              # 160 bytes of data, as expected
```

You can repeat this for allocating FMP space for `b` and initialising the `b` variable.

We want: `b[0] = 1;`

FMP value is `0x160` => 352 bytes of memory are occupied before we have free memory.

We need to:

- Push 0x01 to the stack to be used as the value for b[0]
- Find b[0] in memory, it will be:
- 0x80 + (32 x 5) = 288
so `memory[288:320] = 0x01` (with extra zeros to for the extra 31 bytes)

Various stack manipulations happen but we end up with the following opcode:

```js
>>> Stack 120 1
MSTORE(0x120 0x01)
```

Basically, at 0x120 = 288 bytes, store the value 0x01:

`00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000`

```py
>>> loc = str.find('10') + 1        # use '10' to skip finding 16, then add 1 because 0x01 final char
>>> loc
640
>>> int(loc / 2)
320
```
