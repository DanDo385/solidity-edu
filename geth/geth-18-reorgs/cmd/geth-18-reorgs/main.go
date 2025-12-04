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
    start := flag.Int64("start", 0, "start block")
    count := flag.Int64("count", 20, "number of blocks")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    var prev common.Hash
    for n := *start; n < *start+*count; n++ {
        blk, err := client.BlockByNumber(ctx, big.NewInt(n))
        if err != nil { log.Fatalf("block %d: %v", n, err) }
        if n > *start && blk.ParentHash() != prev {
            fmt.Printf("reorg at block %d: expected parent %s got %s\n", n, prev, blk.ParentHash())
        }
        fmt.Printf("block %d hash=%s parent=%s txs=%d\n", n, blk.Hash(), blk.ParentHash(), len(blk.Transactions()))
        prev = blk.Hash()
    }
}
