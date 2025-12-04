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
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (your own geth node)")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    var version string
    if err := client.Client().CallContext(ctx, &version, "web3_clientVersion"); err != nil { log.Fatalf("clientVersion: %v", err) }
    var peersHex string
    if err := client.Client().CallContext(ctx, &peersHex, "net_peerCount"); err != nil { log.Fatalf("peerCount: %v", err) }
    peers, _ := strconv.ParseInt(peersHex, 0, 64)
    sync, _ := client.SyncProgress(ctx)
    fmt.Printf("Node=%s peers=%d synced=%v\n", version, peers, sync == nil)
}
