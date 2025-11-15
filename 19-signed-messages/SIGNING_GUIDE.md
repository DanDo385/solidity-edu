# EIP-712 Signing Guide

This guide shows you how to create EIP-712 signatures off-chain using JavaScript/TypeScript with ethers.js.

## Table of Contents
- [Setup](#setup)
- [Understanding EIP-712 Structure](#understanding-eip-712-structure)
- [Signing with ethers.js v6](#signing-with-ethersjs-v6)
- [Signing with ethers.js v5](#signing-with-ethersjs-v5)
- [Verifying Signatures](#verifying-signatures)
- [Common Pitfalls](#common-pitfalls)

## Setup

Install dependencies:

```bash
npm install ethers@6
# or for v5
npm install ethers@5
```

## Understanding EIP-712 Structure

EIP-712 signatures require three components:

### 1. Domain
Identifies the signing context (contract, chain, version):

```javascript
const domain = {
    name: 'Project19',
    version: '1',
    chainId: 1, // or await provider.getNetwork().then(n => n.chainId)
    verifyingContract: '0x...' // deployed contract address
};
```

### 2. Types
Defines the structure of your data:

```javascript
const types = {
    Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};
```

**Note**: Don't include `EIP712Domain` in types - it's handled automatically.

### 3. Value
The actual data to sign:

```javascript
const value = {
    owner: '0x...',
    spender: '0x...',
    value: ethers.parseEther('100'),
    nonce: 0,
    deadline: Math.floor(Date.now() / 1000) + 3600 // 1 hour from now
};
```

## Signing with ethers.js v6

### Example 1: Permit Signature

```javascript
import { ethers } from 'ethers';

async function signPermit() {
    // Create wallet (or use browser wallet)
    const privateKey = '0x...';
    const wallet = new ethers.Wallet(privateKey);

    // Define domain
    const domain = {
        name: 'Project19',
        version: '1',
        chainId: 1,
        verifyingContract: '0x...' // your deployed contract
    };

    // Define types
    const types = {
        Permit: [
            { name: 'owner', type: 'address' },
            { name: 'spender', type: 'address' },
            { name: 'value', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ]
    };

    // Define value
    const value = {
        owner: wallet.address,
        spender: '0x...',
        value: ethers.parseEther('100'),
        nonce: 0,
        deadline: Math.floor(Date.now() / 1000) + 3600
    };

    // Sign
    const signature = await wallet.signTypedData(domain, types, value);

    // Split signature into v, r, s
    const sig = ethers.Signature.from(signature);

    console.log('Signature:', signature);
    console.log('v:', sig.v);
    console.log('r:', sig.r);
    console.log('s:', sig.s);

    return { signature, v: sig.v, r: sig.r, s: sig.s };
}
```

### Example 2: Meta-Transaction Signature

```javascript
async function signMetaTx() {
    const wallet = new ethers.Wallet('0x...');

    const domain = {
        name: 'Project19',
        version: '1',
        chainId: 1,
        verifyingContract: '0x...'
    };

    const types = {
        MetaTx: [
            { name: 'from', type: 'address' },
            { name: 'to', type: 'address' },
            { name: 'amount', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ]
    };

    const value = {
        from: wallet.address,
        to: '0x...',
        amount: ethers.parseEther('50'),
        nonce: 0,
        deadline: Math.floor(Date.now() / 1000) + 3600
    };

    const signature = await wallet.signTypedData(domain, types, value);
    const sig = ethers.Signature.from(signature);

    return { v: sig.v, r: sig.r, s: sig.s };
}
```

### Example 3: Voucher Signature (Admin)

```javascript
async function createVoucher(claimer, amount) {
    const adminWallet = new ethers.Wallet('0x...'); // Admin's private key

    const domain = {
        name: 'Project19',
        version: '1',
        chainId: 1,
        verifyingContract: '0x...'
    };

    const types = {
        MetaTx: [ // Reusing MetaTx type
            { name: 'from', type: 'address' },
            { name: 'to', type: 'address' },
            { name: 'amount', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ]
    };

    const value = {
        from: adminWallet.address, // Issuer
        to: claimer,                // Claimer
        amount: amount,
        nonce: 0,                   // Not used for vouchers
        deadline: Math.floor(Date.now() / 1000) + 86400 * 7 // 1 week
    };

    const signature = await adminWallet.signTypedData(domain, types, value);
    const sig = ethers.Signature.from(signature);

    console.log('Voucher created for:', claimer);
    console.log('Amount:', ethers.formatEther(amount), 'ETH');
    console.log('Signature:', signature);

    return { v: sig.v, r: sig.r, s: sig.s };
}
```

## Signing with ethers.js v5

The API is slightly different in v5:

```javascript
import { ethers } from 'ethers';

async function signPermitV5() {
    const wallet = new ethers.Wallet('0x...');

    const domain = {
        name: 'Project19',
        version: '1',
        chainId: 1,
        verifyingContract: '0x...'
    };

    const types = {
        Permit: [
            { name: 'owner', type: 'address' },
            { name: 'spender', type: 'address' },
            { name: 'value', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ]
    };

    const value = {
        owner: wallet.address,
        spender: '0x...',
        value: ethers.utils.parseEther('100'), // Note: utils.parseEther in v5
        nonce: 0,
        deadline: Math.floor(Date.now() / 1000) + 3600
    };

    // Same method name
    const signature = await wallet._signTypedData(domain, types, value);

    // Split signature
    const sig = ethers.utils.splitSignature(signature); // Note: utils.splitSignature in v5

    console.log('v:', sig.v);
    console.log('r:', sig.r);
    console.log('s:', sig.s);

    return sig;
}
```

## Verifying Signatures

### Off-Chain Verification

```javascript
import { ethers } from 'ethers';

function verifySignature(domain, types, value, signature, expectedSigner) {
    // Recover signer from signature
    const recoveredAddress = ethers.verifyTypedData(
        domain,
        types,
        value,
        signature
    );

    console.log('Expected signer:', expectedSigner);
    console.log('Recovered signer:', recoveredAddress);

    return recoveredAddress.toLowerCase() === expectedSigner.toLowerCase();
}

// Usage
const isValid = verifySignature(domain, types, value, signature, wallet.address);
console.log('Signature valid:', isValid);
```

### On-Chain Verification

After signing off-chain, submit to contract:

```javascript
async function submitPermit(contract, owner, spender, value, deadline, signature) {
    const sig = ethers.Signature.from(signature);

    const tx = await contract.permit(
        owner,
        spender,
        value,
        deadline,
        sig.v,
        sig.r,
        sig.s
    );

    await tx.wait();
    console.log('Permit executed:', tx.hash);
}
```

## Common Pitfalls

### 1. Wrong Domain Name or Version

```javascript
// ❌ Wrong - doesn't match contract
const domain = {
    name: 'MyContract', // Contract uses 'Project19'
    version: '2',       // Contract uses '1'
    // ...
};

// ✅ Correct - matches contract exactly
const domain = {
    name: 'Project19',
    version: '1',
    // ...
};
```

### 2. Wrong Chain ID

```javascript
// ❌ Wrong - signing for mainnet but deploying on testnet
const domain = {
    chainId: 1, // Mainnet
    // ...
};

// ✅ Correct - check which chain you're on
const provider = new ethers.JsonRpcProvider('...');
const network = await provider.getNetwork();
const domain = {
    chainId: network.chainId,
    // ...
};
```

### 3. Wrong Verifying Contract

```javascript
// ❌ Wrong - using wrong contract address
const domain = {
    verifyingContract: '0x0000...', // Wrong address
    // ...
};

// ✅ Correct - use actual deployed contract
const contractAddress = await contract.getAddress(); // or contract.address in v5
const domain = {
    verifyingContract: contractAddress,
    // ...
};
```

### 4. Expired Deadline

```javascript
// ❌ Wrong - already expired
const deadline = Math.floor(Date.now() / 1000) - 3600; // 1 hour ago

// ✅ Correct - future timestamp
const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
```

### 5. Wrong Nonce

```javascript
// ❌ Wrong - not checking current nonce
const nonce = 0; // Might be wrong if user already used signatures

// ✅ Correct - query contract for current nonce
const nonce = await contract.nonces(userAddress);
```

### 6. Type Mismatch

```javascript
// ❌ Wrong - type doesn't match contract
const types = {
    Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'amount', type: 'uint256' }, // Contract uses 'value'
        // Missing nonce and deadline
    ]
};

// ✅ Correct - exact match with contract
const types = {
    Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },    // Exact name
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};
```

### 7. Field Order Matters

```javascript
// The order of fields in types MUST match the order in your Solidity struct
// Solidity: Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)

// ❌ Wrong order
const types = {
    Permit: [
        { name: 'value', type: 'uint256' },    // Wrong: value first
        { name: 'owner', type: 'address' },
        // ...
    ]
};

// ✅ Correct order
const types = {
    Permit: [
        { name: 'owner', type: 'address' },    // Correct: owner first
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
    ]
};
```

## Complete Integration Example

```javascript
import { ethers } from 'ethers';

async function main() {
    // Setup
    const provider = new ethers.JsonRpcProvider('http://localhost:8545');
    const wallet = new ethers.Wallet('0x...', provider);

    const contractAddress = '0x...';
    const contractABI = [...]; // Your contract ABI
    const contract = new ethers.Contract(contractAddress, contractABI, wallet);

    // Get current nonce
    const nonce = await contract.nonces(wallet.address);
    console.log('Current nonce:', nonce);

    // Get chain ID
    const network = await provider.getNetwork();
    console.log('Chain ID:', network.chainId);

    // Prepare permit
    const spender = '0x...';
    const value = ethers.parseEther('100');
    const deadline = Math.floor(Date.now() / 1000) + 3600;

    // Define EIP-712 components
    const domain = {
        name: 'Project19',
        version: '1',
        chainId: network.chainId,
        verifyingContract: contractAddress
    };

    const types = {
        Permit: [
            { name: 'owner', type: 'address' },
            { name: 'spender', type: 'address' },
            { name: 'value', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ]
    };

    const valueToSign = {
        owner: wallet.address,
        spender: spender,
        value: value,
        nonce: nonce,
        deadline: deadline
    };

    // Sign
    console.log('Signing permit...');
    const signature = await wallet.signTypedData(domain, types, valueToSign);
    const sig = ethers.Signature.from(signature);

    console.log('Signature created:');
    console.log('  v:', sig.v);
    console.log('  r:', sig.r);
    console.log('  s:', sig.s);

    // Verify off-chain
    const recovered = ethers.verifyTypedData(domain, types, valueToSign, signature);
    console.log('Recovered address:', recovered);
    console.log('Signature valid:', recovered.toLowerCase() === wallet.address.toLowerCase());

    // Submit on-chain
    console.log('Submitting permit transaction...');
    const tx = await contract.permit(
        wallet.address,
        spender,
        value,
        deadline,
        sig.v,
        sig.r,
        sig.s
    );

    console.log('Transaction hash:', tx.hash);
    await tx.wait();
    console.log('Permit executed successfully!');

    // Check allowance
    const allowance = await contract.allowance(wallet.address, spender);
    console.log('Allowance set to:', ethers.formatEther(allowance), 'ETH');
}

main().catch(console.error);
```

## Browser Integration (MetaMask)

```javascript
async function signWithMetaMask() {
    // Request account access
    const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
    });
    const userAddress = accounts[0];

    // Get provider
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();

    const domain = {
        name: 'Project19',
        version: '1',
        chainId: (await provider.getNetwork()).chainId,
        verifyingContract: '0x...'
    };

    const types = {
        Permit: [
            { name: 'owner', type: 'address' },
            { name: 'spender', type: 'address' },
            { name: 'value', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ]
    };

    const value = {
        owner: userAddress,
        spender: '0x...',
        value: ethers.parseEther('100'),
        nonce: 0,
        deadline: Math.floor(Date.now() / 1000) + 3600
    };

    // MetaMask will show a user-friendly signing prompt
    const signature = await signer.signTypedData(domain, types, value);

    console.log('User signed:', signature);
    return signature;
}
```

## Resources

- [EIP-712 Specification](https://eips.ethereum.org/EIPS/eip-712)
- [ethers.js Documentation](https://docs.ethers.org/)
- [MetaMask eth_signTypedData_v4](https://docs.metamask.io/wallet/how-to/sign-data/#use-eth_signtypeddata_v4)
