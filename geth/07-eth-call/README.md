# 07-eth-call: Read-Only Contract Calls

**Goal:** Perform read-only contract calls with manual ABI encoding/decoding.

## Big Picture: Simulating Transactions Without State Changes

`eth_call` simulates a transaction **without persisting state**. You encode function selectors and arguments per ABI, send to the node, and decode the return data. No gas is spent on-chain, but the node executes the EVM locally.

**Computer Science principle:** This is like a **dry run** or **read-only query**. The EVM executes the code, but no state changes are committed. This is perfect for querying view/pure functions.

### The Difference: `eth_call` vs `eth_sendTransaction`

| Aspect | `eth_call` | `eth_sendTransaction` |
|--------|------------|----------------------|
| State changes | ❌ No (simulated) | ✅ Yes (persisted) |
| Gas cost | ❌ No (free) | ✅ Yes (paid) |
| Transaction hash | ❌ No | ✅ Yes |
| Use case | Querying data | Changing state |
| Speed | Fast (local execution) | Slower (needs mining) |

**Key insight:** `eth_call` is for **reading**, `eth_sendTransaction` is for **writing**.

## Learning Objectives

By the end of this module, you should be able to:

1. **Pack ABI** for simple view functions (ERC20 name/symbol/decimals/totalSupply)
2. **Call contracts** with `CallContract` and decode results
3. **Handle reverts** and raw return data
4. **Understand ABI encoding** (function selector + arguments)
5. **Decode return values** based on function return types

## Prerequisites

- **Modules 01-06:** RPC basics, keys/tx basics, transaction building
- **Basic ABI understanding:** Function signatures, parameter types
- **Go basics:** Error handling, type assertions

## Building on Previous Modules

### From Module 05-06 (05-tx-nonces, 06-eip1559)
- You learned to build and send transactions (state-changing)
- Now you're learning to **query** contracts without sending transactions
- Same ABI encoding concepts, but no signing or broadcasting

### From Module 04 (04-accounts-balances)
- You learned to query account balances
- Now you're querying **contract state** (functions, not just balances)
- Contracts can have complex state that requires function calls to read

### Connection to Solidity-edu
- **02 Functions & Payable:** Read/write distinction mirrors view/pure vs state-changing functions
- **03 Events & Logging:** Pair calls with log decoding for richer off-chain views
- **08 ERC20 from Scratch:** ERC20 tokens have view functions (name, symbol, decimals, totalSupply)

## Understanding ABI Encoding

### Function Selector

**Function selector** = First 4 bytes of `keccak256(functionSignature)`

**Example:**
- Function: `name() returns (string)`
- Signature: `"name()"`
- Hash: `keccak256("name()")` = `0x06fdde03...`
- Selector: `0x06fdde03` (first 4 bytes)

**Computer Science principle:** Selectors are like **hash table keys**. They allow the EVM to quickly identify which function to call without parsing the entire function name.

### ABI Encoding Process

1. **Function selector:** First 4 bytes (identifies function)
2. **Arguments:** ABI-encoded parameters (if any)
3. **Result:** Concatenated bytes sent as `data` field

**For functions with no arguments:**
- Data = function selector only (4 bytes)
- Example: `name()` → `0x06fdde03`

**For functions with arguments:**
- Data = function selector + encoded arguments
- Example: `balanceOf(address)` → `0x70a08231` + encoded address

## Real-World Analogies

### The Database Query Analogy
- **`eth_call`:** SELECT query (read-only, no changes)
- **`eth_sendTransaction`:** INSERT/UPDATE query (changes data)
- **ABI encoding:** SQL query syntax
- **Decoding:** Parsing query results

### The Library Analogy
- **`eth_call`:** Asking a librarian to look up information (no changes to books)
- **`eth_sendTransaction`:** Checking out a book (changes library state)
- **Function selector:** Book title/call number
- **Arguments:** Specific page or chapter to read

### The CPU Analogy
- **`eth_call`:** Read-only syscall inspecting memory/state
- **`eth_sendTransaction`:** Syscall that modifies memory/state
- **ABI encoding:** Function call convention (how to pass parameters)

## Fun Facts & Nerdy Details

### Function Selector Collisions

**Problem:** Different function signatures can have the same selector (first 4 bytes)

**Example:**
- `transfer(address,uint256)` → selector `0xa9059cbb`
- `transfer(uint256,address)` → different selector (different order)

**Solution:** Solidity compiler prevents this, but it's theoretically possible with different languages.

**Fun fact:** Selector collisions are extremely rare (4 bytes = 1 in 4 billion chance), but they can happen!

### Revert Handling

**When a contract reverts:**
- `eth_call` returns an error
- Error message may contain revert reason (if contract uses `require()` or `revert()` with message)
- Raw return data contains encoded error information

**Decoding reverts:**
- Error data starts with selector `0x08c379a0` (Error(string) selector)
- Followed by ABI-encoded error message

**Nerdy detail:** Reverts are actually **successful executions** that return error data. The EVM doesn't distinguish between reverts and errors—both return data.

### Gas Estimation with `eth_call`

**`eth_call` can estimate gas:**
- Set `Gas` field in `CallMsg` to estimate required gas
- Node simulates execution and reports gas used
- Useful for estimating transaction costs before sending

**Production tip:** Always estimate gas before sending transactions to avoid failures!

## Comparisons

### Manual ABI vs Typed Bindings
| Aspect | Manual (this module) | Typed Bindings (module 08) |
|--------|---------------------|---------------------------|
| Type safety | ❌ Runtime errors | ✅ Compile-time checks |
| Boilerplate | ❌ High | ✅ Low |
| Flexibility | ✅ High | ❌ Lower |
| Use case | One-off calls | Production code |

### `eth_call` vs `eth_sendTransaction`
| Aspect | `eth_call` | `eth_sendTransaction` |
|--------|------------|----------------------|
| Execution | Local (simulated) | On-chain (persisted) |
| Gas cost | Free | Paid |
| Speed | Fast | Slower (needs mining) |
| State changes | No | Yes |

### Go `ethclient` vs JavaScript `ethers.js`
- **Go:** `client.CallContract(ctx, callMsg, nil)` → Returns `[]byte`
- **JavaScript:** `contract.name()` → Auto-encodes/decodes, returns typed value
- **Same JSON-RPC:** Both use `eth_call` under the hood

## Related Solidity-edu Modules

- **02 Functions & Payable:** Read/write distinction mirrors view/pure vs state-changing functions
- **03 Events & Logging:** Pair calls with log decoding for richer off-chain views
- **08 ERC20 from Scratch:** ERC20 tokens have view functions you'll call in this module

## What You'll Build

In this module, you'll create a CLI that:
1. Takes a contract address and function name as input
2. Encodes the function call using ABI (function selector)
3. Executes `eth_call` to simulate the function execution
4. Decodes the return value based on function type
5. Displays the result

**Key learning:** You'll understand how to manually encode/decode ABI data, giving you full control over contract interactions!

## Files

- **Starter:** `cmd/07-eth-call/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/07-eth-call_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **08-abigen** where you'll:
- Use typed contract bindings (generated code)
- Reduce boilerplate with compile-time type safety
- See how `abigen` generates Go code from ABIs
- Understand the trade-offs between manual and typed approaches
