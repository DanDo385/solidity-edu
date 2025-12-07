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
	// CONFIGURATION: Flags for EIP-1559 Transaction Parameters
	// ============================================================
	// Building on module 05: Same pattern for transaction parameters,
	// but now we add EIP-1559 specific fee caps.
	//
	// New in this module:
	// - maxFeePerGas: Maximum total fee you're willing to pay
	// - maxPriorityFeePerGas: Maximum tip you're willing to pay
	//
	// These caps protect you from unexpected fee spikes.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint (uses INFURA_RPC_URL if set)")
	toHex := flag.String("to", "", "recipient address")
	valueEth := flag.Float64("eth", 0, "ETH to send")
	privHex := flag.String("priv", "", "hex private key (DO NOT use real funds)")
	maxFeeGwei := flag.Float64("maxfee", 30, "maxFeePerGas in gwei")
	maxPrioGwei := flag.Float64("maxtip", 2, "maxPriorityFeePerGas in gwei")
	timeout := flag.Duration("timeout", 15*time.Second, "timeout")
	flag.Parse()

	if *toHex == "" || *privHex == "" {
		log.Fatal("usage: -to <addr> -eth <amount> -priv <hex> [-rpc ...]")
	}

	// ============================================================
	// CONTEXT WITH TIMEOUT: Preventing Hanging Forever
	// ============================================================
	// Same as modules 01-05: Context with timeout prevents hanging.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// ============================================================
	// DIALING THE RPC ENDPOINT: Establishing Connection
	// ============================================================
	// Same as previous modules: Dial JSON-RPC endpoint.
	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// ============================================================
	// KEY MANAGEMENT: Parsing Private Key and Deriving Address
	// ============================================================
	// Building on module 05: Parse private key and derive addresses.
	priv, err := crypto.HexToECDSA(strings.TrimPrefix(*privHex, "0x"))
	if err != nil {
		log.Fatalf("priv: %v", err)
	}
	from := crypto.PubkeyToAddress(priv.Public().(*ecdsa.PublicKey))
	to := common.HexToAddress(*toHex)

	// ============================================================
	// FETCHING PENDING NONCE: Transaction Sequence Number
	// ============================================================
	// Same as module 05: Fetch pending nonce for transaction ordering.
	nonce, err := client.PendingNonceAt(ctx, from)
	if err != nil {
		log.Fatalf("nonce: %v", err)
	}

	// ============================================================
	// CONVERTING GWEI TO WEI: Fee Cap Calculations
	// ============================================================
	// EIP-1559 uses gwei (giga-wei) as a convenient unit for gas prices.
	// 1 gwei = 1,000,000,000 wei = 10^9 wei
	//
	// Why gwei? Gas prices are typically 10-100 gwei, which is easier
	// to work with than trillions of wei.
	//
	// Computer Science principle: Using appropriate units improves
	// readability and reduces errors. Working with gwei is more
	// intuitive than wei for gas prices.
	gwei := big.NewInt(1_000_000_000) // 1 gwei in wei

	// Calculate maxPriorityFeePerGas in wei
	// This is the maximum tip you're willing to pay to validators/miners
	maxPriority := new(big.Int).Mul(big.NewInt(int64(*maxPrioGwei)), gwei)

	// Calculate maxFeePerGas in wei
	// This is your total budget cap (baseFee + tip)
	maxFee := new(big.Int).Mul(big.NewInt(int64(*maxFeeGwei)), gwei)

	// ============================================================
	// CONVERTING ETH TO WEI: Value Calculation
	// ============================================================
	// Same as module 05: Convert ETH to wei.
	// Warning: Using float64 is for demo only! Use big.Rat for production.
	valueWei := new(big.Int).SetUint64(uint64(*valueEth * 1e18))

	// ============================================================
	// SETTING GAS LIMIT: Transaction Resource Budget
	// ============================================================
	// Same as module 05: 21,000 gas for simple ETH transfer.
	gasLimit := uint64(21_000)

	// ============================================================
	// BUILDING EIP-1559 DYNAMIC FEE TRANSACTION
	// ============================================================
	// types.NewTx with DynamicFeeTx creates an EIP-1559 transaction.
	//
	// Key differences from legacy transactions (module 05):
	// - No single gasPrice field
	// - Instead: GasTipCap (priority fee) and GasFeeCap (max total fee)
	// - Base fee is determined by the protocol (not set by user)
	//
	// Transaction structure:
	// - ChainID: Set by signer (we pass nil here, signer fills it)
	// - Nonce: Sequence number (same as legacy)
	// - GasTipCap: Maximum tip (priority fee)
	// - GasFeeCap: Maximum total fee (baseFee + tip)
	// - Gas: Gas limit (same as legacy)
	// - To: Recipient address (pointer, nil for contract creation)
	// - Value: Amount in wei (same as legacy)
	// - Data: Calldata (nil for simple transfer)
	//
	// Computer Science principle: EIP-1559 separates base fee (protocol)
	// from priority fee (user choice). This makes fees more predictable
	// and reduces volatility compared to the legacy auction model.
	tx := types.NewTx(&types.DynamicFeeTx{
		ChainID:   nil, // Filled in by signer via ChainID below
		Nonce:     nonce,
		GasTipCap: maxPriority,
		GasFeeCap: maxFee,
		Gas:       gasLimit,
		To:        &to,
		Value:     valueWei,
		Data:      nil,
	})

	// ============================================================
	// FETCHING CHAIN ID: EIP-155 Replay Protection
	// ============================================================
	// Same as module 05: Fetch chain ID for replay protection.
	chainID, err := client.ChainID(ctx)
	if err != nil {
		log.Fatalf("chainId: %v", err)
	}

	// ============================================================
	// SIGNING TRANSACTION: London Signer for EIP-1559
	// ============================================================
	// Sign the transaction using London signer (EIP-1559 compatible).
	//
	// Key difference from module 05:
	// - Module 05: types.NewEIP155Signer (legacy transactions)
	// - This module: types.NewLondonSigner (EIP-1559 transactions)
	//
	// Both signers include chainID for replay protection, but London
	// signer handles the additional EIP-1559 fields (GasTipCap, GasFeeCap).
	//
	// Signing process (same as module 05):
	// 1. Serialize transaction (RLP encoding, includes EIP-1559 fields)
	// 2. Hash serialized data (Keccak256)
	// 3. Sign hash with private key (ECDSA)
	// 4. Encode signature (v, r, s)
	signed, err := types.SignTx(tx, types.NewLondonSigner(chainID), priv)
	if err != nil {
		log.Fatalf("sign: %v", err)
	}

	// ============================================================
	// SENDING TRANSACTION: Broadcasting to Network
	// ============================================================
	// Same as module 05: Send transaction to network.
	// The transaction will be processed with EIP-1559 fee mechanics.
	if err := client.SendTransaction(ctx, signed); err != nil {
		log.Fatalf("send: %v", err)
	}

	// ============================================================
	// OUTPUT: Displaying Transaction Details
	// ============================================================
	fmt.Printf("Submitted EIP-1559 tx %s\n  from=%s nonce=%d to=%s\n  value=%s wei maxFee=%s maxPriority=%s\n",
		signed.Hash(), from.Hex(), nonce, to.Hex(), valueWei.String(), maxFee.String(), maxPriority.String())

	// ============================================================
	// EDUCATIONAL NOTES & COMPARISONS
	// ============================================================
	//
	// Building on module 05:
	// - Module 05: Legacy transactions with fixed gasPrice
	// - This module: EIP-1559 transactions with dynamic fees
	// - Same nonce management, same signing process, different fee structure
	//
	// Fee mechanics:
	// - Base fee: Set by protocol (algorithmic, burned)
	// - Priority fee: Set by user (tip to validators/miners)
	// - Effective gas price: min(maxFeeCap, baseFee + tip)
	// - Refund: Excess fees are refunded to sender
	//
	// Comparisons:
	// - Legacy vs EIP-1559: Legacy uses fixed price, EIP-1559 uses dynamic fees
	// - EIP155Signer vs LondonSigner: Different signers for different tx types
	//
	// Real-world analogies:
	// - Base fee = bus fare (set by transit authority)
	// - Priority tip = tip for priority boarding (optional)
	// - Max fee = total budget cap
	// - Refund = change back if fees are lower than expected
	//
	// Fun facts:
	// - Base fee adjusts by 12.5% per block based on fullness
	// - EIP-1559 has burned over 4 million ETH (deflationary mechanism)
	// - Gas prices are typically quoted in gwei (convenient unit)
	//
	// Production tips:
	// - Use precise wei math (no float) for production
	// - Estimate gas limit with CallMsg for contract calls
	// - Consider dynamic tips based on network conditions
	//
	// Next steps (module 07):
	// - You'll learn to call contracts without sending transactions (eth_call)
	// - Encode function calls manually (ABI encoding)
	// - Decode return values
	// - Understand view/pure functions vs state-changing functions
}
