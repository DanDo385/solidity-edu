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
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    toHex := flag.String("to", "", "recipient address")
    valueEth := flag.Float64("eth", 0, "ETH to send")
    privHex := flag.String("priv", "", "hex private key (test only)")
    maxFeeGwei := flag.Float64("maxfee", 30, "maxFeePerGas gwei")
    maxPrioGwei := flag.Float64("maxtip", 2, "maxPriorityFeePerGas gwei")
    timeout := flag.Duration("timeout", 15*time.Second, "timeout")
    flag.Parse()

    if *toHex == "" || *privHex == "" {
        log.Fatal("usage: -to <addr> -eth <amount> -priv <hex>")
    }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    priv, err := crypto.HexToECDSA(strings.TrimPrefix(*privHex, "0x"))
    if err != nil { log.Fatalf("priv: %v", err) }
    from := crypto.PubkeyToAddress(priv.Public().(*ecdsa.PublicKey))
    to := common.HexToAddress(*toHex)

    nonce, err := client.PendingNonceAt(ctx, from)
    if err != nil { log.Fatalf("nonce: %v", err) }

    gwei := big.NewInt(1_000_000_000)
    maxPriority := new(big.Int).Mul(big.NewInt(int64(*maxPrioGwei)), gwei)
    maxFee := new(big.Int).Mul(big.NewInt(int64(*maxFeeGwei)), gwei)
    valueWei := new(big.Int).SetUint64(uint64(*valueEth * 1e18))
    gasLimit := uint64(21000)

    tx := types.NewTx(&types.DynamicFeeTx{
        Nonce:     nonce,
        GasTipCap: maxPriority,
        GasFeeCap: maxFee,
        Gas:       gasLimit,
        To:        &to,
        Value:     valueWei,
    })

    chainID, err := client.ChainID(ctx)
    if err != nil { log.Fatalf("chainId: %v", err) }

    signed, err := types.SignTx(tx, types.NewLondonSigner(chainID), priv)
    if err != nil { log.Fatalf("sign: %v", err) }
    if err := client.SendTransaction(ctx, signed); err != nil { log.Fatalf("send: %v", err) }

    fmt.Printf("sent EIP-1559 tx %s\n", signed.Hash())
}
