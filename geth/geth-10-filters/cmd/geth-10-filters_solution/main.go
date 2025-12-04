package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "time"

    "github.com/ethereum/go-ethereum"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    ws := flag.Bool("ws", false, "treat RPC as websocket for subscriptions")
    blocks := flag.Int("blocks", 3, "how many latest blocks to poll (fallback)")
    flag.Parse()

    // EDUCATIONAL NOTES:
    // - WS lets you subscribe (push); HTTP forces polling. Use WS for live UIs/indexers.
    // - newHeads subscription is cheap; log filters via WS are also possible.
    // - Reorg detection: store block hash by number; mismatch means rewind and rescan.
    // - Analogy: live news ticker (WS) vs refreshing the newspaper website (polling).
    client, err := ethclient.Dial(*rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    if *ws {
        // Subscribe to new heads (WS only).
        heads := make(chan *types.Header)
        sub, err := client.SubscribeNewHead(context.Background(), heads)
        if err != nil {
            log.Fatalf("subscribe: %v", err)
        }
        fmt.Println("listening for new heads (ctrl+c to exit)...")
        for {
            select {
            case err := <-sub.Err():
                log.Fatalf("sub err: %v", err)
            case h := <-heads:
                fmt.Printf("new head #%d hash=%s parent=%s\n", h.Number.Uint64(), h.Hash(), h.ParentHash)
            }
        }
    }

    // HTTP fallback: poll latest N blocks and show headers.
    head, err := client.HeaderByNumber(context.Background(), nil)
    if err != nil {
        log.Fatalf("head: %v", err)
    }
    latest := head.Number.Uint64()
    start := latest - uint64(*blocks) + 1
    for n := start; n <= latest; n++ {
        h, err := client.HeaderByNumber(context.Background(), big.NewInt(int64(n)))
        if err != nil {
            log.Fatalf("header %d: %v", n, err)
        }
        fmt.Printf("head #%d hash=%s parent=%s\n", n, h.Hash(), h.ParentHash)
    }

    // Reorg hint: if stored parentHash doesn’t match previously seen hash, a reorg happened.
    // Analogy: watching the tape of new ledger pages; if a page references a different prev page, the story changed.
    _ = ethereum.FilterQuery{} // placeholder to show filters exist for logs too
}
