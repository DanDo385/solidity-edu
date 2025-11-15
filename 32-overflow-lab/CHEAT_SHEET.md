# Integer Overflow/Underflow Cheat Sheet

## Quick Reference for Project 32

### Overflow/Underflow Basics

```solidity
// OVERFLOW: uint256 wraps around at max value
uint256 max = type(uint256).max;  // 2^256 - 1
max + 1 = 0  // Wraps to zero!
max + 2 = 1  // Wraps to one!

// UNDERFLOW: uint256 wraps around at zero
uint256 min = 0;
min - 1 = type(uint256).max  // Wraps to max!
min - 2 = type(uint256).max - 1  // Wraps to max-1!

// uint8 example (easier to visualize)
uint8 maxU8 = 255;
maxU8 + 1 = 0   // Overflow
uint8 minU8 = 0;
minU8 - 1 = 255 // Underflow
```

### Pre-0.8.0 vs 0.8.0+

| Aspect | Pre-0.8.0 | 0.8.0+ |
|--------|-----------|--------|
| **Default Behavior** | Wraps silently | Reverts on overflow |
| **Protection** | Manual (SafeMath) | Automatic |
| **Gas Cost** | Higher with SafeMath | Lower (optimized) |
| **Safety** | Developer's responsibility | Safe by default |
| **Opt-out** | N/A | `unchecked { }` block |

### SafeMath Patterns (Pre-0.8.0)

```solidity
library SafeMath {
    // Addition: Check result >= a
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");
        return c;
    }

    // Subtraction: Check b <= a
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "underflow");
        return a - b;
    }

    // Multiplication: Check (a*b)/a == b
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "overflow");
        return c;
    }

    // Division: Check b > 0
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "division by zero");
        return a / b;
    }
}

// Usage
using SafeMath for uint256;
balance = balance.sub(amount);  // Safe
balance = balance.add(amount);  // Safe
```

### Modern Solidity (0.8.0+)

```solidity
// Automatic checks - no library needed!
balance -= amount;  // Reverts on underflow
balance += amount;  // Reverts on overflow
total = a * b;      // Reverts on overflow
```

### Unchecked Blocks (0.8.0+)

```solidity
// Opt-out of automatic checks
unchecked {
    // Arithmetic here can overflow/underflow
    balance -= amount;  // Silent wrap if underflow
    total += value;     // Silent wrap if overflow
}
```

### When to Use Unchecked: Decision Tree

```
┌─────────────────────────────────────┐
│ Should I use unchecked?             │
└─────────────────────────────────────┘
           │
           ▼
    ┌─────────────────────┐
    │ User-controlled?    │───YES──▶ ❌ DON'T USE
    └─────────────────────┘
           │ NO
           ▼
    ┌─────────────────────┐
    │ Financial calc?     │───YES──▶ ❌ DON'T USE
    └─────────────────────┘
           │ NO
           ▼
    ┌─────────────────────┐
    │ Can prove no        │───NO───▶ ❌ DON'T USE
    │ overflow?           │
    └─────────────────────┘
           │ YES
           ▼
    ┌─────────────────────┐
    │ Critical gas        │───NO───▶ ❌ DON'T USE
    │ optimization?       │           (stay safe)
    └─────────────────────┘
           │ YES
           ▼
        ✅ USE (document!)
```

### Safe Unchecked Patterns

#### ✅ Pattern 1: Loop Counter
```solidity
for (uint256 i = 0; i < array.length;) {
    // Process array[i]
    unchecked { i++; }  // Safe: bounded by length
}
// WHY SAFE: i < array.length always, can't overflow
```

#### ✅ Pattern 2: After Explicit Check
```solidity
function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
    require(a >= b, "underflow");
    unchecked {
        return a - b;  // Safe: we just checked a >= b
    }
}
// WHY SAFE: require() ensures no underflow
```

#### ✅ Pattern 3: Known Bounds
```solidity
function discount(uint256 price) public pure returns (uint256) {
    require(price <= 1000);
    unchecked {
        return price - price / 10;  // Safe: price >= price/10
    }
}
// WHY SAFE: Mathematical proof of safety
```

#### ✅ Pattern 4: Countdown Loop
```solidity
for (uint256 i = 10; i > 0;) {
    // Process
    unchecked { i--; }  // Safe: loop condition prevents underflow
}
// WHY SAFE: Loop stops at i > 0
```

### Dangerous Unchecked Patterns

#### ❌ Pattern 1: User Input
```solidity
function bad(uint256 userValue) public {
    unchecked {
        balance -= userValue;  // DANGER: User controls value!
    }
}
// WHY UNSAFE: Attacker can cause underflow
```

#### ❌ Pattern 2: Financial Calculations
```solidity
function bad(uint256 amount) public {
    unchecked {
        reward = stake * multiplier;  // DANGER: Can overflow!
        balance += reward;
    }
}
// WHY UNSAFE: Financial values must be exact
```

#### ❌ Pattern 3: External Data
```solidity
function bad(uint256 externalPrice) public {
    unchecked {
        total = externalPrice * quantity;  // DANGER!
    }
}
// WHY UNSAFE: External data is untrusted
```

#### ❌ Pattern 4: Timestamp Arithmetic
```solidity
function bad(uint256 delay) public {
    unchecked {
        unlockTime = block.timestamp + delay;  // DANGER!
    }
}
// WHY UNSAFE: Could overflow to past, bypass lock
```

### Historical Exploits

#### BeautyChain (BEC) - April 2018
```solidity
// THE BUG
function batchTransfer(address[] _receivers, uint256 _value) {
    uint256 amount = _receivers.length * _value;  // OVERFLOW!
    require(balances[msg.sender] >= amount);
    // ... transfers
}

// THE EXPLOIT
recipients = [addr1, addr2]  // length = 2
value = 2^255
amount = 2 * 2^255 = 0  // OVERFLOW TO ZERO!
require(balance >= 0)  // ✓ Passes!
// Transferred 2^255 tokens to each address from nothing!

// IMPACT: $1B market cap lost, trading halted
```

#### SMT Token - April 2018
```solidity
// THE BUG
function transferProxy(address _from, address _to, uint256 _value, uint256 _fee) {
    uint256 _total = _value + _fee;  // OVERFLOW!
    require(balances[_from] >= _total);
    // ... transfers
}

// THE EXPLOIT
value = 2^256 - 1  // MAX_UINT256
fee = 1
total = (2^256 - 1) + 1 = 0  // OVERFLOW TO ZERO!
require(balance >= 0)  // ✓ Passes!
// Transferred max value with zero balance requirement!

// IMPACT: Token became worthless
```

### Testing Overflow/Underflow

```solidity
// Test overflow (0.8+)
vm.expectRevert(stdError.arithmeticError);
uint256 x = type(uint256).max + 1;

// Test underflow (0.8+)
vm.expectRevert(stdError.arithmeticError);
uint256 y = 0 - 1;

// Test SafeMath protection
vm.expectRevert("SafeMath: addition overflow");
SafeMath.add(type(uint256).max, 1);

// Test vulnerable (unchecked) version
unchecked {
    uint256 z = 0 - 1;
    assert(z == type(uint256).max);  // Wrapped!
}
```

### Gas Optimization Examples

```solidity
// EXPENSIVE (checked)
function expensive(uint256[] calldata data) public pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < data.length; i++) {  // Checked i++
        sum += data[i];
    }
    return sum;
}

// CHEAPER (unchecked loop counter)
function cheaper(uint256[] calldata data) public pure returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < data.length;) {
        sum += data[i];  // Keep sum checked!
        unchecked { i++; }  // Save gas here
    }
    return sum;
}

// SAVINGS: ~30 gas per iteration
// For 100 iterations: ~3,000 gas saved
```

### Type Ranges

```solidity
uint8:   0 to 255 (2^8 - 1)
uint16:  0 to 65,535 (2^16 - 1)
uint32:  0 to 4,294,967,295 (2^32 - 1)
uint64:  0 to 18,446,744,073,709,551,615 (2^64 - 1)
uint128: 0 to 340,282,366,920,938,463,463,374,607,431,768,211,455 (2^128 - 1)
uint256: 0 to ~10^77 (2^256 - 1)

int8:    -128 to 127
int16:   -32,768 to 32,767
int256:  -2^255 to 2^255 - 1
```

### Common Test Values

```solidity
// Maximum values
type(uint8).max    // 255
type(uint256).max  // 2^256 - 1

// Useful test values
uint256 halfMax = 2**255;       // Half of max
uint256 almostMax = type(uint256).max - 1;
uint256 zero = 0;

// Overflow triggers
type(uint256).max + 1  // Overflows to 0
0 - 1                  // Underflows to max
2**128 * 2**128        // Overflows (2^256)
```

### Quick Commands

```bash
# Run all tests
forge test

# Run specific exploit test
forge test --match-test testBeautyChainExploit -vvv

# Run SafeMath tests
forge test --match-test SafeMath

# Compare gas costs
forge test --match-test testGasDifference -vvv

# Run with full traces
forge test -vvvv

# Run with gas reporting
forge test --gas-report
```

### Security Checklist

When reviewing code:

- [ ] Check Solidity version (< 0.8.0 = vulnerable by default)
- [ ] Look for arithmetic operations on user input
- [ ] Verify SafeMath usage in pre-0.8 contracts
- [ ] Audit all unchecked blocks
- [ ] Test with boundary values (0, max, max-1, etc.)
- [ ] Ensure financial calculations are never unchecked
- [ ] Check for downcasting without validation
- [ ] Test batch operations for overflow
- [ ] Verify timestamp arithmetic
- [ ] Check supply tracking calculations

### Conversion Guide: SafeMath → 0.8+

```solidity
// OLD (Pre-0.8.0 with SafeMath)
using SafeMath for uint256;

balance = balance.sub(amount);
balance = balance.add(amount);
total = value.mul(price);
result = numerator.div(denominator);

// NEW (0.8.0+)
// Remove SafeMath import and using statement

balance -= amount;  // Automatic underflow check
balance += amount;  // Automatic overflow check
total = value * price;  // Automatic overflow check
result = numerator / denominator;  // Automatic zero check
```

### Key Takeaways

1. **Pre-0.8.0**: Arithmetic wraps silently → Use SafeMath
2. **0.8.0+**: Arithmetic checked automatically → SafeMath not needed
3. **Unchecked**: Opt-out of checks → Only when proven safe
4. **Loop Counters**: Most common safe use of unchecked
5. **Financial Math**: Never use unchecked
6. **User Input**: Never use unchecked
7. **Always Document**: Why unchecked is safe in each case

### Remember

> One integer overflow destroyed a $1B token (BeautyChain).
> Understanding overflow is not optional for Solidity developers.

---

**Need more details?** See README.md for comprehensive explanations.
**Want to practice?** Complete the TODOs in Project32.sol.
**Want to see exploits?** Run the tests in Project32.t.sol.
