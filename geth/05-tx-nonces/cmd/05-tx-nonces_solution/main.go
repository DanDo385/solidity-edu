package main

import (
	"context"
	"crypto/ecdsa"
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	// ============================================================
	// CONFIGURATION: Flags for Transaction Parameters
	// ============================================================
	// Building on modules 01-04: Same pattern for reading RPC URL
	// from environment variables with flag overrides.
	//
	// New in this module: We accept transaction parameters:
	// - Recipient address (-to)
	// - ETH amount to send (-eth)
	// - Private key (-priv) - WARNING: Test only! Never use real keys!
	//
	// Security warning: In production, never pass private keys via
	// command-line arguments. Use keystore files (module 03) or
	// hardware wallets instead.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	toHex := flag.String("to", "", "recipient address")
	valueEth := flag.Float64("eth", 0.0, "ETH to send")
	privHex := flag.String("priv", "", "hex private key (test only)")
	timeout := flag.Duration("timeout", 15*time.Second, "timeout")
	flag.Parse()

	// ============================================================
	// INPUT VALIDATION: Required Parameters
	// ============================================================
	if *toHex == "" || *privHex == "" {
		log.Fatal("usage: -to <addr> -eth <amount> -priv <hex>")
	}

	// ============================================================
	// KEY MANAGEMENT: Parsing Private Key and Deriving Address
	// ============================================================
	// Building on module 03: Parse private key from hex string
	// and derive the sender address.
	//
	// common.HexToAddress converts hex string to address type
	// crypto.HexToECDSA converts hex string to private key
	// crypto.PubkeyToAddress derives address from public key
	//
	// Note: We trim "0x" prefix if present (common in hex strings)
	to := common.HexToAddress(*toHex)
	priv, err := crypto.HexToECDSA(strings.TrimPrefix(*privHex, "0x"))
	if err != nil {
		log.Fatalf("priv: %v", err)
	}
	from := crypto.PubkeyToAddress(priv.Public().(*ecdsa.PublicKey))

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	// Same as modules 01-02: Context with timeout prevents hanging.
	// We use a longer timeout (15 seconds) since sending transactions
	// can take longer than simple queries.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	// Same as modules 01-02: Dial JSON-RPC endpoint.
	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// FETCHING PENDING NONCE: Transaction Sequence Number
	// ============================================================
	// PendingNonceAt returns the next nonce to use, including
	// pending transactions in the mempool.
	//
	// Computer Science principle: Nonces ensure ordering and
	// prevent replay attacks. Each transaction from an address
	// must use a sequential nonce (0, 1, 2, 3, ...).
	//
	// Why "pending"? If you have transactions pending in the
	// mempool, you need to account for them. Otherwise, you'll
	// create nonce conflicts.
	//
	// JSON-RPC call: {"method": "eth_getTransactionCount", "params": [address, "pending"], "id": 1}
	// Response: {"result": "0x5", "id": 1} (hex-encoded nonce)
	nonce, err := client.PendingNonceAt(ctx, from)
	if err != nil {
		log.Fatalf("nonce: %v", err)
	}

	// ============================================================
	// FETCHING SUGGESTED GAS PRICE: Fee Estimation
	// ============================================================
	// SuggestGasPrice returns a recommended gas price in wei.
	// This is based on recent block gas prices.
	//
	// Computer Science principle: Gas price is a market mechanism.
	// Higher prices = faster inclusion, lower prices = slower inclusion.
	//
	// Note: This is for legacy transactions. EIP-1559 (module 06)
	// uses dynamic fees (base fee + tip) instead.
	//
	// JSON-RPC call: {"method": "eth_gasPrice", "params": [], "id": 1}
	// Response: {"result": "0x4a817c800", "id": 1} (hex-encoded wei)
	gasPrice, err := client.SuggestGasPrice(ctx)
	if err != nil {
		log.Fatalf("gasPrice: %v", err)
	}

	// ============================================================
	// CONVERTING ETH TO WEI: Precision Handling
	// ============================================================
	// Convert ETH amount to wei (smallest unit).
	// 1 ETH = 10^18 wei
	//
	// Warning: Using float64 multiplication is for demo only!
	// For production, use big.Rat or decimal libraries to avoid
	// precision loss. Floating-point arithmetic can introduce errors.
	//
	// Example: 0.1 ETH * 1e18 = 100000000000000000 wei
	valueWei := big.NewInt(int64(*valueEth * 1e18))

	// ============================================================
	// SETTING GAS LIMIT: Transaction Resource Budget
	// ============================================================
	// Gas limit is the maximum gas the transaction can consume.
	// For a simple ETH transfer, 21,000 gas is standard.
	//
	// Computer Science principle: Gas limit prevents infinite loops
	// and resource exhaustion. If a transaction exceeds its gas limit,
	// it fails (reverts) but still consumes gas up to the limit.
	//
	// Fun fact: 21,000 gas is the minimum for any transaction.
	// Contract calls require more gas depending on complexity.
	gasLimit := uint64(21000) // simple ETH transfer

	// ============================================================
	// BUILDING LEGACY TRANSACTION: Transaction Construction
	// ============================================================
	// types.NewTransaction creates a legacy transaction with:
	// - Nonce: Sequence number
	// - To: Recipient address
	// - Value: Amount in wei
	// - GasLimit: Maximum gas to consume
	// - GasPrice: Price per unit of gas
	// - Data: Calldata (nil for simple transfer)
	//
	// Transaction structure:
	// - LegacyTx: Pre-EIP-1559 format (this module)
	// - AccessListTx: EIP-2930 (optional access lists)
	// - DynamicFeeTx: EIP-1559 (module 06)
	tx := types.NewTransaction(nonce, to, valueWei, gasLimit, gasPrice, nil)

	// ============================================================
	// FETCHING CHAIN ID: EIP-155 Replay Protection
	// ============================================================
	// Building on module 01: Fetch chain ID for EIP-155 replay protection.
	//
	// EIP-155 includes chainID in the transaction signature to prevent
	// cross-chain replay attacks. A transaction signed for mainnet (chainID 1)
	// cannot be replayed on Sepolia (chainID 11155111).
	//
	// Computer Science principle: This is a form of domain separation.
	// Each chain has its own domain (chainID), and signatures are bound
	// to that domain.
	chainID, err := client.ChainID(ctx)
	if err != nil {
		log.Fatalf("chainId: %v", err)
	}

	// ============================================================
	// SIGNING TRANSACTION: Cryptographic Authentication
	// ============================================================
	// Sign the transaction using EIP-155 signer (includes chainID).
	//
	// Signing process:
	// 1. Serialize transaction (RLP encoding)
	// 2. Hash serialized data (Keccak256)
	// 3. Sign hash with private key (ECDSA)
	// 4. Encode signature (v, r, s)
	//
	// Computer Science principle: Signing the hash (not raw data) is
	// more efficient and secure. The hash is fixed-size (32 bytes)
	// regardless of transaction size.
	//
	// types.NewEIP155Signer creates a signer that includes chainID in
	// the signature, preventing cross-chain replay attacks.
	signed, err := types.SignTx(tx, types.NewEIP155Signer(chainID), priv)
	if err != nil {
		log.Fatalf("sign: %v", err)
	}

	// ============================================================
	// SENDING TRANSACTION: Broadcasting to Network
	// ============================================================
	// SendTransaction broadcasts the signed transaction to the network.
	//
	// What happens:
	// 1. Transaction is sent to the node's mempool
	// 2. Node propagates it to peers via gossip protocol
	// 3. Validators/miners pick it up and include it in a block
	// 4. Transaction is executed and state changes are applied
	//
	// Note: This only submits the transaction. It doesn't wait for
	// confirmation. Use module 15 (receipts) to check transaction status.
	//
	// JSON-RPC call: {"method": "eth_sendRawTransaction", "params": [signedTxHex], "id": 1}
	// Response: {"result": "0x1234...", "id": 1} (transaction hash)
	if err := client.SendTransaction(ctx, signed); err != nil {
		log.Fatalf("send: %v", err)
	}

	// ============================================================
	// OUTPUT: Displaying Transaction Details
	// ============================================================
	fmt.Printf("sent tx %s\n  from=%s nonce=%d to=%s value=%s wei gasPrice=%s\n",
		signed.Hash(), from.Hex(), nonce, to.Hex(), valueWei.String(), gasPrice.String())

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on previous modules:
	// - Module 03: Private keys and address derivation
	// - Module 04: Account balances (now we're changing them!)
	// - Module 01: Chain ID (now used for replay protection)
	//
	// Connection to Solidity:
	// - Transactions execute Solidity contracts
	// - msg.sender is the from address
	// - msg.value is the value sent
	//
	// Comparisons:
	// - Legacy (this module) vs EIP-1559 (module 06): Legacy uses fixed gasPrice, EIP-1559 uses dynamic fees
	// - PendingNonceAt vs NonceAt: Pending includes mempool, NonceAt is historical
	//
	// Real-world analogies:
	// - Nonce = ticket number in a queue
	// - Gas price = bid for priority processing
	// - Transaction = signed message that changes state
	//
	// Warnings:
	// - Do NOT use real keys on mainnet in this demo code
	// - Prefer EIP-1559 fees (module 06) for production
	// - Wait for receipt (module 15) to confirm transaction
	//
	// Next steps (module 06):
	// - You'll learn EIP-1559 dynamic fee transactions
	// - Understand base fee + priority tip mechanics
	// - Use the modern transaction format (recommended for production)
}
