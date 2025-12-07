# 09-events: Decoding ERC20 Transfer Events

**Goal:** Decode ERC20 Transfer logs and understand topics vs data.

## Big Picture: Events as Append-Only History

Events/logs are append-only "newspaper clippings" emitted during transaction execution. Indexed params go into topics (bloom-filtered for search); non-indexed go into data. This is the off-chain friendly history of state changes.

**Computer Science principle:** Events are like **write-ahead logs** or **audit trails**. They provide a searchable history of state changes without storing full state snapshots.

### Event Structure

**Topics (indexed parameters):**
- `Topics[0]`: Event signature hash (keccak256("Transfer(address,address,uint256)"))
- `Topics[1]`: First indexed parameter (from address)
- `Topics[2]`: Second indexed parameter (to address)
- `Topics[3]`: Third indexed parameter (if any)

**Data (non-indexed parameters):**
- ABI-encoded non-indexed parameters
- For Transfer: `value` (uint256) is in data

**Key insight:** Indexed parameters are searchable (via bloom filters), non-indexed are cheaper to store.

## Learning Objectives

By the end of this module, you should be able to:

1. **Build a filter query** for a token's Transfer events over a block range
2. **Decode indexed vs non-indexed** params with ABI
3. **Understand log roots/bloom filters** in block headers
4. **Filter events** by address and topic

## Prerequisites

- **Modules 01-08:** RPC basics, ABI basics, contract calls
- **Basic understanding:** Events, logs, transaction receipts

## Building on Previous Modules

### From Module 08 (08-abigen)
- You learned to call contract functions
- Now you're **listening to events** emitted by those functions
- Events complement function calls - they show what happened

### From Module 02 (02-rpc-basics)
- You learned about blocks and transactions
- Events are stored in **transaction receipts** (module 15)
- Block headers include `logsBloom` for efficient event queries

### Connection to Solidity-edu
- **03 Events & Logging:** Schema design and gas trade-offs
- **01 Datatypes & Storage:** Logs sit outside storage; cheaper than writing state history
- **08 ERC20 from Scratch:** ERC20 Transfer events are what you'll decode

## Understanding Event Structure

### Transfer Event Example

**Solidity:**
```solidity
event Transfer(address indexed from, address indexed to, uint256 value);
```

**Emitted log:**
- `Topics[0]`: `keccak256("Transfer(address,address,uint256)")` = `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef`
- `Topics[1]`: `from` address (padded to 32 bytes)
- `Topics[2]`: `to` address (padded to 32 bytes)
- `Data`: ABI-encoded `value` (uint256)

**Computer Science principle:** Indexed parameters are like database indexes - they make queries fast but cost more gas to emit.

### Bloom Filters in Block Headers

**Block headers include `logsBloom`:**
- Bloom filter of all event topics in the block
- Allows fast "does this block contain Transfer events?" queries
- Probabilistic data structure (may have false positives, never false negatives)

**Fun fact:** Bloom filters are named after Burton Howard Bloom (1970). They're used in databases, caches, and blockchain systems!

## Real-World Analogies

### The Newspaper Analogy
- **Topics:** Bold headlines (indexed, searchable)
- **Data:** Article body (non-indexed, cheaper)
- **Logs:** Newspaper clippings (append-only history)
- **Bloom filters:** Index of headlines (fast search)

### The Database Audit Log Analogy
- **Events:** Audit log entries
- **Topics:** Indexed columns (fast queries)
- **Data:** Non-indexed columns (full details)
- **Filtering:** SQL WHERE clauses

### The Git Commit Analogy
- **Events:** Commit messages
- **Topics:** Commit tags/labels (searchable)
- **Data:** Full commit message (details)

## Fun Facts & Nerdy Details

### Event Signature Hash

**Calculation:**
1. Event signature: `"Transfer(address,address,uint256)"`
2. Hash: `keccak256(signature)` = `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef`
3. This is `Topics[0]` for all Transfer events

**Fun fact:** The same event signature always produces the same hash. This allows filtering by event type!

### Gas Costs: Indexed vs Non-Indexed

**Indexed parameters:**
- Cost: ~375 gas per indexed parameter
- Benefit: Searchable via bloom filters
- Use case: Addresses, small integers

**Non-indexed parameters:**
- Cost: ~8 gas per byte
- Benefit: Cheaper for large data
- Use case: Strings, large arrays, structs

**Production tip:** Index only what you need to search by!

### Log Limits

**Maximum topics:** 4 (including event signature)
**Maximum data:** ~24KB per log
**Maximum logs per transaction:** Limited by gas

**Nerdy detail:** Logs are stored in the receipts trie, separate from the state trie. This keeps state queries fast while allowing rich event history.

## Comparisons

### Topics vs Data
| Aspect | Topics (Indexed) | Data (Non-Indexed) |
|--------|-----------------|-------------------|
| Searchable | ✅ Yes (bloom filters) | ❌ No |
| Gas cost | Higher (~375 per param) | Lower (~8 per byte) |
| Max size | 32 bytes per topic | ~24KB total |
| Use case | Addresses, small ints | Strings, large data |

### FilterLogs vs SubscribeLogs
| Aspect | FilterLogs | SubscribeLogs |
|--------|-----------|--------------|
| Protocol | HTTP (polling) | WebSocket (push) |
| Use case | Historical queries | Real-time monitoring |
| Efficiency | Lower (polling) | Higher (push) |

### Go `ethclient` vs JavaScript `ethers.js`
- **Go:** `client.FilterLogs(ctx, query)` → Returns `[]types.Log`
- **JavaScript:** `contract.queryFilter(eventFilter, fromBlock, toBlock)` → Returns `Event[]`
- **Same JSON-RPC:** Both use `eth_getLogs` under the hood

## Related Solidity-edu Modules

- **03 Events & Logging:** Schema design and gas trade-offs
- **01 Datatypes & Storage:** Logs sit outside storage; cheaper than writing state history
- **08 ERC20 from Scratch:** ERC20 Transfer events are what you'll decode

## What You'll Build

In this module, you'll create a CLI that:
1. Takes a token address and block range as input
2. Builds a FilterQuery for Transfer events
3. Fetches logs matching the filter
4. Decodes indexed parameters (from, to) from topics
5. Decodes non-indexed parameters (value) from data
6. Displays Transfer events with block number, tx hash, from, to, value

**Key learning:** You'll understand how events work, how to filter them, and how to decode them!

## Files

- **Starter:** `cmd/09-events/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/09-events_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **10-filters** where you'll:
- Subscribe to new block headers via WebSocket
- Poll headers as a fallback (HTTP)
- Understand real-time vs polling approaches
- Detect chain reorganizations
