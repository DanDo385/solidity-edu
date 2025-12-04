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
    valueEth := flag.Float64("eth", 0.0, "ETH to send")
    privHex := flag.String("priv", "", "hex private key (test only)")
    timeout := flag.Duration("timeout", 15*time.Second, "timeout")
    flag.Parse()

    if *toHex == "" || *privHex == "" {
        log.Fatal("usage: -to <addr> -eth <amount> -priv <hex>")
    }

    to := common.HexToAddress(*toHex)
    priv, err := crypto.HexToECDSA(strings.TrimPrefix(*privHex, "0x"))
    if err != nil { log.Fatalf("priv: %v", err) }
    from := crypto.PubkeyToAddress(priv.Public().(*ecdsa.PublicKey))

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    nonce, err := client.PendingNonceAt(ctx, from)
    if err != nil { log.Fatalf("nonce: %v", err) }
    gasPrice, err := client.SuggestGasPrice(ctx)
    if err != nil { log.Fatalf("gasPrice: %v", err) }

    valueWei := big.NewInt(int64(*valueEth * 1e18))
    gasLimit := uint64(21000)
    tx := types.NewTransaction(nonce, to, valueWei, gasLimit, gasPrice, nil)

    chainID, err := client.ChainID(ctx)
    if err != nil { log.Fatalf("chainId: %v", err) }

    signed, err := types.SignTx(tx, types.NewEIP155Signer(chainID), priv)
    if err != nil { log.Fatalf("sign: %v", err) }

    if err := client.SendTransaction(ctx, signed); err != nil {
        log.Fatalf("send: %v", err)
    }

    fmt.Printf("sent tx %s nonce=%d to=%s value=%s\n", signed.Hash(), nonce, to.Hex(), valueWei.String())
}
