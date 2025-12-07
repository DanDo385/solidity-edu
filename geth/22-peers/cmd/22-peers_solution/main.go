package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "strconv"
    "time"

    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (peer info best via own node)")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    // EDUCATIONAL NOTES:
    // - net_peerCount is hex per JSON-RPC; admin_peers (richer) usually disabled on public RPCs.
    // - More healthy peers = fresher gossip of txs/blocks; fewer peers can mean isolation/staleness.
    // - Analogy: number of radio stations your node can hear; more stations = better news propagation.
    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    var peersHex string
    if err := client.Client().CallContext(ctx, &peersHex, "net_peerCount"); err != nil {
        log.Fatalf("peerCount: %v", err)
    }
    peers, _ := strconv.ParseInt(peersHex, 0, 64)
    fmt.Printf("Peers: %d (hex %s)\n", peers, peersHex)

    // admin_peers (rich info) requires enabling admin API; not available on most public RPCs.
    // Analogy: counting how many neighbors your node is gossiping with.
}
