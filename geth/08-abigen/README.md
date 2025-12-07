# 08-abigen: Typed Contract Bindings

**Goal:** Use typed contract bindings (abigen-style) for safer calls and transactions.

## Big Picture: From Manual to Typed

abigen turns ABI into typed Go methods. Instead of manual ABI pack/unpack (module 07), you get compile-time checked methods with `CallOpts` and `TransactOpts` for read/write. This reduces boilerplate and errors.

**Computer Science principle:** This is **code generation** - converting a schema (ABI) into type-safe code. It's like generating API clients from OpenAPI specs, or database models from schemas.

### The Evolution: Manual → Typed

**Module 07 (Manual):**
```go
data, _ := abi.Pack("name")
raw, _ := client.CallContract(ctx, callMsg, nil)
var name string
abi.UnpackIntoInterface(&name, "name", raw)
```

**Module 08 (Typed):**
```go
name, _ := contract.Name(ctx)
```

**Key benefit:** Compile-time type safety + less boilerplate!

## Learning Objectives

By the end of this module, you should be able to:

1. **Understand how abigen bindings** wrap `BoundContract` with typed methods
2. **Make typed view calls** (name/symbol/decimals/balanceOf)
3. **See how `CallOpts` and `TransactOpts`** carry context, block number, signer info
4. **Compare manual vs typed** approaches and their trade-offs

## Prerequisites

- **Module 07 (07-eth-call):** Manual ABI calls and Go interfaces
- **Go basics:** Interfaces, type assertions, error handling

## Building on Previous Modules

### From Module 07 (07-eth-call)
- You learned manual ABI encoding/decoding
- Now you're using **typed bindings** that handle encoding/decoding automatically
- Same underlying JSON-RPC calls, but with better ergonomics

### From Module 04 (04-accounts-balances)
- You learned to query account balances
- Now you're querying **contract functions** with type safety
- Balance queries can use typed bindings too!

### Connection to Solidity-edu
- **Events & Logging:** Bindings can also decode events (module 09)
- **Contract interactions:** Matches front-end libraries but in Go

## Understanding BoundContract

### What is BoundContract?

**BoundContract** = Contract address + ABI + Backend (RPC client)

It provides:
- **Call():** For view functions (read-only)
- **Transact():** For state-changing functions (write)
- **FilterLogs():** For event queries

**Computer Science principle:** This is the **adapter pattern** - wrapping low-level RPC calls with a high-level interface.

### CallOpts vs TransactOpts

**CallOpts** (for read operations):
- `Context`: For cancellation/timeouts
- `BlockNumber`: Which block to query (nil = latest)
- `From`: Optional sender address (for view functions that check `msg.sender`)

**TransactOpts** (for write operations):
- `Context`: For cancellation/timeouts
- `From`: Sender address
- `Signer`: Transaction signer function
- `Value`: ETH to send
- `GasPrice` / `GasFeeCap` / `GasTipCap`: Gas pricing
- `GasLimit`: Maximum gas to consume
- `Nonce`: Transaction nonce

**Key insight:** `CallOpts` is lightweight (just context), `TransactOpts` includes signing info.

## Real-World Analogies

### The Typed Remote Control Analogy
- **Manual ABI:** Raw hex payloads (like sending raw IR codes)
- **Typed Bindings:** Labeled buttons (like a TV remote with labeled buttons)
- **BoundContract:** The remote control itself
- **CallOpts/TransactOpts:** Settings (volume, channel, etc.)

### The CPU Analogy
- **Manual ABI:** Hand-rolled assembly (full control, error-prone)
- **Typed Bindings:** Syscall stubs (type-safe, less boilerplate)
- **BoundContract:** System call interface

### The Database ORM Analogy
- **Manual ABI:** Raw SQL queries
- **Typed Bindings:** ORM methods (type-safe, less boilerplate)
- **BoundContract:** Database connection + schema

## Fun Facts & Nerdy Details

### abigen Code Generation

**abigen CLI tool:**
```bash
abigen --abi token.abi --bin token.bin --pkg token --out token.go
```

**What it generates:**
- Typed contract struct
- Methods for each function (with proper types)
- Event structs and filters
- Helper functions

**Fun fact:** abigen reads Solidity compiler output (ABI JSON + bytecode) and generates Go code. It's like protobuf code generation!

### Type Safety Benefits

**Compile-time checks:**
- Wrong function name → Compile error
- Wrong argument types → Compile error
- Wrong return type → Compile error

**Runtime benefits:**
- Less error handling (types are guaranteed)
- Better IDE autocomplete
- Easier refactoring

**Nerdy detail:** Go's type system catches errors at compile time, preventing runtime failures. This is especially valuable for contract interactions where errors can be expensive!

### BoundContract Internals

**Under the hood:**
1. BoundContract stores ABI + address
2. `Call()` encodes function call using ABI
3. Executes `eth_call` via backend
4. Decodes return value using ABI
5. Returns typed Go value

**Same JSON-RPC:** Still uses `eth_call` under the hood, just with better ergonomics!

## Comparisons

### Manual ABI vs Typed Bindings
| Aspect | Manual (module 07) | Typed (this module) |
|--------|-------------------|-------------------|
| Type safety | ❌ Runtime errors | ✅ Compile-time checks |
| Boilerplate | ❌ High | ✅ Low |
| Flexibility | ✅ High | ❌ Lower |
| Use case | One-off calls | Production code |
| Learning | ✅ Understand internals | ✅ Faster development |

### CallOpts vs TransactOpts
| Aspect | CallOpts | TransactOpts |
|--------|----------|--------------|
| Use case | Read operations | Write operations |
| Signing | ❌ No | ✅ Yes |
| Gas pricing | ❌ No | ✅ Yes |
| Complexity | Low | High |

### Go abigen vs JavaScript ethers.js
- **Go:** Compile-time type safety, code generation
- **JavaScript:** Runtime type safety, dynamic typing
- **Same concept:** Both provide typed contract interfaces

## Related Solidity-edu Modules

- **Events & Logging:** Bindings can also decode events (module 09)
- **Contract interactions:** Matches front-end libraries but in Go
- **08 ERC20 from Scratch:** ERC20 tokens are perfect for learning bindings

## What You'll Build

In this module, you'll create a CLI that:
1. Takes a token address and optional holder address as input
2. Creates a BoundContract from ABI and address
3. Calls typed methods (Name, Symbol, Decimals, BalanceOf)
4. Displays token information and balance

**Key learning:** You'll see how typed bindings simplify contract interactions while maintaining type safety!

## Files

- **Starter:** `cmd/08-abigen/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/08-abigen_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **09-events** where you'll:
- Decode ERC20 Transfer events
- Understand topics vs data in logs
- Filter events by block range
- See how events complement function calls
