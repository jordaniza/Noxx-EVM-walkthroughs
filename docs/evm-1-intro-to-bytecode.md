# Understanding Bytecode

The evm processes bytecode as a series of instructions sent to the execution layer, for example:

```
60003560e01c80632e64cec11461003b5780636057361d1461005957
```

If we go to [The EVM Opcode Page](https://www.ethervm.io/), we can deconstruct as follows:

```sh
60 PUSH(uint8) 00           # push the value 00 on to the stack
35 CALLDATALOAD             # load the first value on the stack into i:i+32 
                            # loaded 00 into calldata
60 PUSH(uint8) e0           # push e0 onto the stack
1c                          # 256 bit shift right
```
...etc (we will come back to this)

## Function signatures

Define the function signature as 4 bytes (8 characters of hex) of the keccak256 hash of the function name:

```js
// example function
function doStuff(address _to) public { /* */ }

// sig string
"doStuff(address)"

// hash
"373cf23c710cb05bc335f291b632bd5850910a740614e32783c487b47f38ddc3"

// sig
"373cf23c"
```

If we were to look at the function loaded into a word on the calldata, we would get:
```
0x373cf23c0000000000000000000000008e851e94e1667Cd76Dda1A49f258934E2BCDCF3e
  --------                        ----------------------------------------   
  signature                                        argument
```
What we would therefore need with the above function is to run a function call the to 0x373cf23, having pushed the address to calldata.

## Back to our example

```
60003560e01c80632e64cec11461003b5780636057361d1461005957
```

Note: this assumes we are calling the solidity function:

```js
"store(uint256)" // 6057361d
```

Calldata therefore has:
```            
                                                            1st 32 Bytes    
                                                                  |
0x6057361d00000000000000000000000000000000000000000000000000000000|0000000a
  --------                                                        |      --   
"store(uint256)"                                                        10 (decimal)
```


```sh
60 PUSH(uint8) 00           # push the value 00 on to the stack
35 CALLDATALOAD             # load the first value from calldata to the stack with an offset of i:i+32
                            # i = 0 from before, so it will load the first 32 bytes of calldata
                            # if this is a function string, it will be the function signature, but will exclude the last 4 bytes of data
                            # 0x6057361d00000000000000000000000000000000000000000000000000000000
60 PUSH(uint8) e0           # push e0 onto the stack (224 in decimal)
1c                          # 256 bit shift right
                            # first 2 items on stack are 224, 0x6057361d....00
                            # This trims 0x6057361d00000000000000000000000000000000000000000000000000000000 to 0x6057361d
80 DUP                      # Duplicate what is currently on the stack
63 PUSH(uint32) 0x2e64cec1  # push the function sig for "retrieve()" on to the stack
14 EQ                       # compare stack items 0 and 1, if they are equal, return true, else return false
                            # this compares 0x2e64cec1 with 0x6057361d and replaces them with 0 (false) on the stack
61 PUSH(uint16) 003b        # push 003b to the stack (59 in decimal)
57 JUMPI                    # jump to destination I if condition is met    
                            # stack is 59, 0. So: DO NOT jump to program counter location 59 (condition false)
80 DUP                      # Duplicate 0x6057361d again
63 PUSH(uint32) 0x6057361d  # Push 0x6057361d to stack (you should recognise this)
14 EQ                       # compare stack items 0 and 1, if they are equal, return true, else return false
                            # Now they are true, so replace 0x6057361d, 0x6057361d with 1
61 PUSH(uint16) 0059        # push 0059 to the stack (89 in decimal)
57 JUMPI                    # jump to destination I if condition is met
                            # stack is 89, 1. So: DO jump to program counter location 89 (condition true)
```

After JUMPI there must be a JUMPDEST, at which point execution resumes, in this case, with a PUSH1 00 (0x6000)


# Quick refresher on bit shifting

Bit shifting is very simple multiplication and division in binary.

* Shift right halves (integer division)
* Shift left doubles

Example:

```py
#!/bin/python
>>> 0b1111
15            
>>> 0b1111 >> 1
7         
>>> 0b0111
7            
>>> 0b0111 << 1
14       

>>> shift = 0x6057361d00000000000000000000000000000000000000000000000000000000 >> 224
>>> hex(shift)
'0x6057361d'
```

# EVM Playground Link

https://www.evm.codes/playground?unit=Wei&callData=0x6057361d000000000000000000000000000000000000000000000000000000000000000a&codeType=Mnemonic&code=%27!0~0KCALLDATALOAD~2z2qw!E0~3KSHR~5z2qwDUP1~6(X4_2E64CEC1~7KEQ~12z5qwX2_3B~13(*I~16z3qwDUP1~17KX4_6057361D~18KEQ~23z5qwX2_59~24K*I~27z3qwkY%20wX30_0~28KwZGV59z31q!1~60%20%7BG%7DW%7DKwkYwX26_0~62z2qKZstore%7Buint256V89z27q!0%20ZContinueW.KK%27~%20ZOffset%20z%20%7Bprevious%20instruFoccupies%20w%5Cnq)s%7DwkZThes-ar-just%20paddingNenabl-usNgetN_%200xZ%2F%2F%20Yprogram%20counter%2059%20%26%2089XPUSHW%20funFexecution...V%7D)codew*DEST~N%20to(wwGretrieve%7BFction%20-e%20*JUMP)%20byte(%20K!X1_%01!()*-FGKNVWXYZ_kqwz~_