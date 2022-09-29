# Events

Let's query block [15001871](https://etherscan.io/txs?block=15001871): 

```sh
# set RPC
export RPC=https://rpc.ankr.com/eth
export DEST=docs/7

# fetch block
cast block 15001871 --json --rpc-url $RPC | tee $DEST/block.json

# fetch the first transaction
cast tx 0x311ba3a0affb00510ae3f0a36c5bcd0a48cdb23d803bbc16f128639ffb9e3e58 --rpc-url=$RPC --json | tee $DEST/tx.json

# transaction receipts
cast receipt 0x311ba3a0affb00510ae3f0a36c5bcd0a48cdb23d803bbc16f128639ffb9e3e58 --rpc-url=$RPC --json | tee $DEST/receipt.json
```

You'll notice 3 separate RPC requests on our side aggregate the data. [Etherscan](https://etherscan.io/tx/0x311ba3a0affb00510ae3f0a36c5bcd0a48cdb23d803bbc16f128639ffb9e3e58) aggregates a lot of this info very handily for us, but it's important to remember what comes where:

**Block**
- Hash, stateRoot, receiptsRoot, logsBloom, txRoot

**Tx**
- Very limited information, but does contain the input of the transaction

- 136 hex characters:
    - 2 x 32 byte words
    - 1 x 4 byte function sig

```js

// transfer(address,uint256)
a9059cbb 

// address
00000000 00000000 00000000 ec23e787 
ea25230f 74a3da0f 515825c1 d820f47a

// 45251000 in uint256
00000000 00000000 00000000 00000000 
00000000 00000000 00000000 02b279b8
```

**Receipt**
- Gas used
- Gas price
- logs and logsBloom


## Anatomy of Event Logs

Indexed events allow for querying, you can have up to 3 indexes but a max of 4 topics. 

Why? The first topic is the hash of the event signature.

Non-indexed events are stored in the `data` field.

Event data are loaded into the logs.topics and logs.data using the `LOG{0-4}` set of opcodes, these take in:

offset length [topic1 topic2 topic3 topic4]*

Where:
    logs.topics = [topic1,topic2,topic3,topic4]
    logs.data = memory[offset:offset+length]


## Bloom Filters

A bloom filter is an efficient way of querying large datasets for hashes.

If hashes are globally unique, they become relatively slow to search for on gigantic databases.

A bloom filter collapses many hashes together and storing the value as a bit vector. The bit vector flips certain values based on the input function. This means we can aggregate the result of multiple hashes into a single filter and check if a value is definitely not in the filter.

Example: 

```js
// H(x) is the hash of x
H(a) != H(b) != H(c)

// B(x) is the bloom filter of x

// in this example, running the filter on H(a) and H(b) gives an aggregate filter B
B(H(a)) + B(H(b)) = B

// B^-1(x) = is x in the filter
B^-1(H(a)) == "maybe"*
B^-1(H(c)) == false

// d was not in there but returns a positive
B^-1(H(d)) == "maybe"*
```

The benefit is that I can very quickly run the bloom filter on a value *and check if it is **definitely not** in a given set*.

*The drawback is that I lose certainty. Bloom filters will generate false positives: values that when run through `B(x)` return `B` but are NOT `a` nor `b`.

This is why we call them filters - we can definitely exclude variables from sets, but we cannot establish membership.

There is a tradeoff between query speed and false positive:

- Larger bitvectors will have a smaller FP rate (less hashes collapse together)
- Larger bitvectors will be slower to compute and query

## Querying Logs

Log queries work by saying:

> "Get me all logs with signature X" = topic 1 (the hash of the event signature)

> "Get me all logs with signature X between block A and B"

> "Get me all logs with signature X and topic 2 = Y"

You can see in the receipts that a logsBloom is generated for the Tx, and the block header also has a logsBloom.

The bloom in the header is 512 hex characters = 256 bytes = 2048 bits.

Our query can then be done via:

- Get our query in terms of its bloom value
- Iterate over the logsBloom in the block headers (10m+ entries)
- For all matching blooms, query the logsBloom of the transaction receipts
- For all matching txBlooms, query the logs directly

You can see how this reduces the search space significantly.


# References

[EVM Deep Dive](https://noxx.substack.com/p/evm-deep-dives-the-path-to-shadowy-16e)