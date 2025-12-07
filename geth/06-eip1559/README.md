# 06-eip1559: Dynamic Fee Transactions (EIP-1559)

**Goal:** Build/send an EIP-1559 (dynamic fee) transaction and understand base fee + tip math.

## Big Picture: The London Upgrade and Dynamic Fees

Post-London (August 2021), Ethereum uses **dynamic fees** instead of fixed gas prices. This makes fee estimation more predictable and reduces fee volatility.

**Computer Science principle:** EIP-1559 introduces a **two-part fee structure**:
- **Base Fee:** Algorithmically determined, **burned** (removed from supply)
- **Priority Fee (Tip):** Paid to validators/miners, incentivizes inclusion

This is more efficient than the legacy auction model where users bid against each other.

## Learning Objectives

By the end of this module, you should be able to:

1. **Construct a DynamicFeeTx** with maxFeePerGas and maxPriorityFeePerGas
2. **Convert user inputs** (gwei) to wei safely
3. **Sign with London signer** (chainID-aware) and broadcast
4. **Understand fee math:** effectiveGasPrice = min(maxFeeCap, baseFee + tip)
5. **Understand refunds:** Excess fees are refunded to the sender

## Prerequisites

- **Module 05 (05-tx-nonces):** Legacy transaction flow, nonces, signing
- **Comfort with:** ETH units, RPC basics, transaction concepts
- **Go basics:** Big integers, error handling

## Building on Previous Modules

### From Module 05 (05-tx-nonces)
- You learned to build legacy transactions with fixed `gasPrice`
- Now you're building **EIP-1559 transactions** with dynamic fees
- Same nonce management, same signing process, different fee structure

### From Module 01 (01-stack)
- You learned about chainID
- EIP-1559 transactions also use chainID for replay protection
- London signer includes chainID in the signature

### Connection to Solidity-edu
- **Functions & Payable:** Gas budgeting affects send/withdraw patterns
- **Gas & Storage lessons:** Understanding gas pricing is critical for optimizing costs

## Understanding EIP-1559 Fee Structure

### The Two-Part Fee System

**Base Fee:**
- **Set by protocol:** Algorithmically determined based on block fullness
- **Burned:** Removed from ETH supply (deflationary mechanism)
- **Variable:** Adjusts up/down by 12.5% per block based on target (50% full blocks)
- **Predictable:** Users can estimate base fee for next block

**Priority Fee (Tip):**
- **Set by user:** How much you're willing to pay for faster inclusion
- **Paid to validators:** Incentivizes block inclusion
- **Optional:** Can be 0 (transaction will still be included, just slower)

### Fee Caps and Refunds

**maxFeePerGas:** Maximum you're willing to pay total (baseFee + tip)
**maxPriorityFeePerGas:** Maximum tip you're willing to pay

**Effective gas price calculation:**
```
effectiveGasPrice = min(maxFeePerGas, baseFee + maxPriorityFeePerGas)
```

**Refund calculation:**
```
refund = (maxFeePerGas - effectiveGasPrice) * gasUsed
```

**Key insight:** You set caps to protect yourself from fee spikes. If baseFee rises unexpectedly, you're protected by maxFeePerGas.

## Real-World Analogies

### The Bus Fare Analogy
- **Base Fee:** Standard bus fare (set by transit authority, everyone pays)
- **Priority Tip:** Tip for priority boarding (optional, goes to driver)
- **Max Fee:** Your total budget cap (base fare + max tip you're willing to pay)
- **Refund:** If base fare is lower than expected, you get change back

### The Restaurant Analogy
- **Base Fee:** Menu price (set by restaurant)
- **Priority Tip:** Gratuity (optional, goes to server)
- **Max Fee:** Your total budget (menu price + max tip)
- **Refund:** If bill is less than budget, you get change

### The Auction Analogy (Legacy vs EIP-1559)
- **Legacy:** Everyone bids against each other (volatile, unpredictable)
- **EIP-1559:** Base price + optional tip (predictable, efficient)

## Fun Facts & Nerdy Details

### Base Fee Algorithm

The base fee adjusts based on block fullness:
- **Target:** 50% block fullness (15M gas out of 30M limit)
- **If block > 50% full:** Base fee increases by 12.5%
- **If block < 50% full:** Base fee decreases by 12.5%

**Mathematical formula:**
```
baseFee_new = baseFee_old * (1 + (gasUsed - targetGas) / targetGas / 8)
```

**Fun fact:** The 12.5% adjustment rate was chosen to balance responsiveness with stability. Too fast = volatile, too slow = unresponsive.

### Fee Burning: Deflationary Mechanism

**Before EIP-1559:** All fees went to miners/validators (inflationary)

**After EIP-1559:** Base fee is burned (removed from supply)

**Impact:** During high network activity, more ETH is burned than issued, making ETH deflationary!

**Nerdy detail:** As of 2024, Ethereum has burned over 4 million ETH (worth billions of dollars) through base fee burning.

### Gas Price Units

- **wei:** Smallest unit (1 ETH = 10^18 wei)
- **gwei:** Common unit for gas prices (1 gwei = 10^9 wei)
- **ETH:** Rarely used for gas prices (too large)

**Why gwei?** It's a convenient middle ground. Gas prices are typically 10-100 gwei, which is easier to work with than trillions of wei.

## Comparisons

### Legacy vs EIP-1559 Transactions
| Aspect | Legacy (module 05) | EIP-1559 (this module) |
|--------|-------------------|----------------------|
| Fee structure | Single `gasPrice` | `baseFee + tip` |
| Predictability | Low (auction model) | High (algorithmic base fee) |
| Refunds | No | Yes (excess refunded) |
| Status | Still works | Recommended for production |
| Signer | EIP155Signer | LondonSigner |

### maxFeePerGas vs maxPriorityFeePerGas
| Field | Purpose | Who Sets It |
|-------|---------|-------------|
| `maxFeePerGas` | Total budget cap | User |
| `maxPriorityFeePerGas` | Tip cap | User |
| `baseFee` | Base fee | Protocol (algorithmic) |

### Go `ethclient` vs JavaScript `ethers.js`
- **Go:** `types.NewTx(&types.DynamicFeeTx{...})` → Build transaction struct
- **JavaScript:** `populateTransaction()` + `signer.sendTransaction()` → Auto-populates EIP-1559
- **Same JSON-RPC:** Both use `eth_sendRawTransaction` under the hood

## Related Solidity-edu Modules

- **02 Functions & Payable:** Gas budgeting affects send/withdraw patterns
- **06 Mappings, Arrays & Gas:** Understanding gas pricing is critical for optimizing costs
- **07 Reentrancy & Security:** Gas costs affect security patterns (gas griefing attacks)

## What You'll Build

In this module, you'll create a CLI that:
1. Takes recipient address, ETH amount, private key, and fee caps as input
2. Fetches the pending nonce (same as module 05)
3. Converts gwei to wei for fee caps
4. Builds an EIP-1559 DynamicFeeTx
5. Signs with London signer (includes chainID)
6. Sends the transaction to the network
7. Displays transaction hash and fee details

**Key learning:** You'll understand the modern transaction format and dynamic fee mechanics!

## Files

- **Starter:** `cmd/06-eip1559/main.go` - Your starting point with TODO comments
- **Solution:** `cmd/06-eip1559_solution/main.go` - Complete implementation with detailed comments

## Next Steps

After completing this module, you'll move to **07-eth-call** where you'll:
- Call contract functions without sending transactions
- Encode function calls manually (ABI encoding)
- Decode return values
- Understand the difference between `eth_call` and `eth_sendTransaction`
