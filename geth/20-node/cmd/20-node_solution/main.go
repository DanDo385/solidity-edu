package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "strconv"
    "time"

    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (your own geth node)")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    // EDUCATIONAL NOTES:
    // - web3_clientVersion shows client + version; peerCount hints at p2p health.
    // - admin/nodeInfo lives in admin API (often disabled on HTTP); use IPC for full info.
    // - Analogy: checking the health board: software version, how many neighbors, and sync status.
    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    // Basic node info via web3_clientVersion.
    var version string
    if err := client.Client().CallContext(ctx, &version, "web3_clientVersion"); err != nil {
        log.Fatalf("clientVersion: %v", err)
    }

    // Peer count via net_peerCount.
    var peersHex string
    if err := client.Client().CallContext(ctx, &peersHex, "net_peerCount"); err != nil {
        log.Fatalf("peerCount: %v", err)
    }
    peers, _ := strconv.ParseInt(peersHex, 0, 64)

    sync, _ := client.SyncProgress(ctx)
    synced := sync == nil

    fmt.Printf("Node: %s\nPeers: %d\nSynced: %v\n", version, peers, synced)

    // Commentary:
    // - admin/nodeInfo requires IPC or --http.api admin; often disabled on public RPC.
    // - Peer count from net_peerCount is hex string per JSON-RPC spec.
    // - SyncProgress nil means fully synced; otherwise shows progress fields.
    // Analogy: checking the health board of your node: software version, how many neighbors, and whether it's caught up.
    _ = os.Getenv
}
