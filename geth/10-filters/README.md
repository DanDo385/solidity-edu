# 10-filters: Real-Time Block Monitoring

**Goal:** Practice filters and subscriptions (newHeads), and understand polling vs websockets.

## Big Picture: Push vs Pull

Filters let you query past logs; subscriptions push new data (heads/logs) over websockets. When WS isn't available, you poll. Detecting reorgs means comparing parent hashes to what you stored.

**Computer Science principle:** This is the **push vs pull** pattern:
- **Pull (Polling):** Client asks "any updates?" periodically
- **Push (Subscriptions):** Server tells client "here's an update!" immediately

### WebSocket vs HTTP

**WebSocket (Push):**
- Persistent connection
- Server pushes updates immediately
- Lower latency
- More efficient for real-time monitoring

**HTTP (Pull/Polling):**
- Request-response model
- Client asks for updates periodically
- Higher latency
- Fallback when WebSocket unavailable

**Key insight:** WebSocket is better for real-time, HTTP polling is more reliable (works everywhere).

## Learning Objectives

By the end of this module, you should be able to:

1. **Subscribe to `newHeads`** over WebSocket
2. **Poll latest headers** over HTTP fallback
3. **Understand reorg detection** via parent hash mismatch
4. **Compare push vs pull** approaches

## Prerequisites

- **Modules 01-09:** RPC basics, logs, events
- **Basic understanding:** WebSocket vs HTTP, real-time systems

## Building on Previous Modules

### From Module 09 (09-events)
- You learned to filter logs (historical queries)
- Now you're **subscribing to new blocks** (real-time monitoring)
- Same filtering concepts, different protocol (WebSocket vs HTTP)

### From Module 02 (02-rpc-basics)
- You learned to fetch block headers
- Now you're **monitoring** headers in real-time
- Headers include parent hash for reorg detection

### Connection to Solidity-edu
- **Events & Logging:** Same filtering applies to logs
- **Reorg handling:** Pairs with module 18 (rescan on mismatch)

## Understanding Subscriptions

### WebSocket Subscriptions

**Available subscriptions:**
- `newHeads`: New block headers
- `logs`: New logs matching filter
- `pendingTransactions`: New pending transactions

**How it works:**
1. Open WebSocket connection
2. Send subscription request
3. Receive updates as they happen
4. Handle connection errors gracefully

**Computer Science principle:** This is the **observer pattern** - subscribing to events and receiving notifications.

### Polling Fallback

**When WebSocket unavailable:**
- Use HTTP polling
- Periodically query latest block
- Compare with previous block number
- Handle missed blocks

**Trade-offs:**
- ✅ Works everywhere (HTTP is universal)
- ❌ Higher latency (polling interval)
- ❌ Less efficient (repeated requests)

## Real-World Analogies

### The News Ticker Analogy
- **WebSocket:** Live news ticker (updates pushed immediately)
- **HTTP Polling:** Refreshing news website (checking periodically)
- **Reorgs:** Breaking news corrections (story changed)

### The Radio Analogy
- **WebSocket:** Live radio broadcast (continuous stream)
- **HTTP Polling:** Checking radio schedule (periodic checks)
- **Reorgs:** Program changes (schedule updated)

### The Git Watch Analogy
- **WebSocket:** `git watch` (notifications on commits)
- **HTTP Polling:** `git log` periodically (checking for new commits)
- **Reorgs:** Force push (history rewritten)

## Fun Facts & Nerdy Details

### WebSocket Endpoints

**Different URLs:**
- HTTP: `https://mainnet.infura.io/v3/YOUR_KEY`
- WebSocket: `wss://mainnet.infura.io/v3/YOUR_KEY`

**Fun fact:** `wss://` is WebSocket Secure (like `https://` for HTTP). It uses TLS encryption.

### Reorg Detection

**How to detect reorgs:**
1. Store block hash by block number
2. When new block arrives, check parent hash
3. If parent hash doesn't match stored hash → reorg happened
4. Rewind to common ancestor and rescan

**Nerdy detail:** Reorgs happen when two blocks are mined at the same height. The chain with more work becomes canonical, the other is orphaned.

### Subscription Limits

**Public RPC providers:**
- May limit WebSocket connections
- May rate-limit subscriptions
- May require authentication

**Production tip:** Run your own node for unlimited subscriptions!

## Comparisons

### WebSocket vs HTTP Polling
| Aspect | WebSocket | HTTP Polling |
|--------|-----------|--------------|
| Latency | Low (immediate) | High (polling interval) |
| Efficiency | High (push) | Low (repeated requests) |
| Reliability | Lower (connection issues) | Higher (works everywhere) |
| Use case | Real-time monitoring | Fallback, simple queries |

### newHeads vs FilterLogs
| Aspect | newHeads | FilterLogs |
|--------|----------|------------|
| Protocol | WebSocket (push) | HTTP (pull) |
| Use case | Real-time blocks | Historical logs |
| Efficiency | High (push) | Lower (polling) |

### Go `ethclient` vs JavaScript `ethers.js`
- **Go:** `client.SubscribeNewHead(ctx, heads)` → Returns `Subscription`
- **JavaScript:** `provider.on('block', callback)` → Event emitter
- **Same concept:** Both subscribe to new blocks

## Related Solidity-edu Modules

- **03 Events & Logging:** Same filtering applies to logs
- **18 Reorgs:** Pairs with reorg handling (rescan on mismatch)

## What You'll Build

In this module, you'll create a CLI that:
1. Supports WebSocket mode (subscriptions) or HTTP mode (polling)
2. If WebSocket: Subscribe to new block headers, print as they arrive
3. If HTTP: Poll latest N blocks and print headers
4. Display block number, hash, and parent hash
5. Show how to detect reorgs (parent hash mismatch)

**Key learning:** You'll understand real-time monitoring vs polling, and how to detect chain reorganizations!

## Files

- **Starter:** `cmd/10-filters/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/10-filters_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **11-storage** where you'll:
- Query contract storage slots directly
- Understand storage layout (mappings, arrays)
- Learn about storage proofs
- Connect to Solidity storage concepts from module 01
