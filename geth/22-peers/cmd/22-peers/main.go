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
    rpc := flag.String("rpc", "http://localhost:8545", "RPC (peer info)")
    timeout := flag.Duration("timeout", 5*time.Second, "timeout")
    flag.Parse()

    ctx, cancel := context.WithTimeout(context.Background(), *timeout)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    var peersHex string
    if err := client.Client().CallContext(ctx, &peersHex, "net_peerCount"); err != nil { log.Fatalf("peerCount: %v", err) }
    peers, _ := strconv.ParseInt(peersHex, 0, 64)
    fmt.Printf("Peers: %d (hex %s)\n", peers, peersHex)
}
