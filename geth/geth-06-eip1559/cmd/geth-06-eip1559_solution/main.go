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
	// Flags for RPC, keys, recipient, and fee caps.
	defaultRPC := os.Getenv("INFURA_RPC_URL")
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/INFURA_RPC_URLPC_URL"
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

	// Context guards network calls.
	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	// Parse key and derive sender.
	priv, err := crypto.HexToECDSA(strings.TrimPrefix(*privHex, "0x"))
	if err != nil {
		log.Fatalf("priv: %v", err)
	}
	from := crypto.PubkeyToAddress(priv.Public().(*ecdsa.PublicKey))
	to := common.HexToAddress(*toHex)

	// Nonce from pending pool.
	nonce, err := client.PendingNonceAt(ctx, from)
	if err != nil {
		log.Fatalf("nonce: %v", err)
	}

	// Gas tip and cap (EIP-1559). Convert gwei → wei.
	gwei := big.NewInt(1_000_000_000)
	maxPriority := new(big.Int).Mul(big.NewInt(int64(*maxPrioGwei)), gwei)
	maxFee := new(big.Int).Mul(big.NewInt(int64(*maxFeeGwei)), gwei)

	// Value in wei (simple float conversion; for precision use big.Rat in prod).
	valueWei := new(big.Int).SetUint64(uint64(*valueEth * 1e18))

	// Gas limit estimate for a simple transfer.
	gasLimit := uint64(21_000)

	// Build dynamic fee tx.
	tx := types.NewTx(&types.DynamicFeeTx{
		ChainID:   nil, // filled in by signer via ChainID below
		Nonce:     nonce,
		GasTipCap: maxPriority,
		GasFeeCap: maxFee,
		Gas:       gasLimit,
		To:        &to,
		Value:     valueWei,
		Data:      nil,
	})

	chainID, err := client.ChainID(ctx)
	if err != nil {
		log.Fatalf("chainId: %v", err)
	}

	signed, err := types.SignTx(tx, types.NewLondonSigner(chainID), priv)
	if err != nil {
		log.Fatalf("sign: %v", err)
	}

	if err := client.SendTransaction(ctx, signed); err != nil {
		log.Fatalf("send: %v", err)
	}

	fmt.Printf("Submitted EIP-1559 tx %s\n  from=%s nonce=%d to=%s\n  value=%s wei maxFee=%s maxPriority=%s\n",
		signed.Hash(), from.Hex(), nonce, to.Hex(), valueWei.String(), maxFee.String(), maxPriority.String())

	// Commentary:
	// - baseFee is set by protocol; actual effectiveGasPrice = min(maxFee, baseFee+tip).
	// - Using ChainID avoids cross-chain replay (EIP-155).
	// - For production, use precise wei math and consider gas estimation with CallMsg.
	// Analogy: maxFee is your total budget; tip is your extra incentive for inclusion; baseFee is toll everyone pays.
}
