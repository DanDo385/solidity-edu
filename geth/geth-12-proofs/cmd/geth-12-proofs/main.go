package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" { defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY" }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    accountHex := flag.String("account", "", "account to prove")
    slot := flag.Uint64("slot", 0, "storage slot to prove")
    block := flag.Int64("block", -1, "block number (-1=latest)")
    timeout := flag.Duration("timeout", 8*time.Second, "timeout")
    flag.Parse()

    if *accountHex == "" { log.Fatal("usage: -account <addr> [-slot N] [-block num]") }

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    var slots []string
    slots = []string{fmt.Sprintf("0x%x", *slot)}
    var blockNum *big.Int
    if *block >= 0 { blockNum = big.NewInt(*block) }

    proof, err := client.GetProof(ctx, common.HexToAddress(*accountHex), slots, blockNum)
    if err != nil { log.Fatalf("getProof: %v", err) }
    fmt.Printf("balance=%s nonce=%d codeHash=%s storageHash=%s proofs=%d\n", proof.Balance, proof.Nonce, proof.CodeHash.Hex(), proof.StorageHash.Hex(), len(proof.AccountProof))
    if len(proof.StorageProof) > 0 {
        sp := proof.StorageProof[0]
        fmt.Printf("slot %s value=%s proofs=%d\n", sp.Key, sp.Value, len(sp.Proof))
    }
}
