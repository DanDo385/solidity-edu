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
    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - WebSocket mode (-ws, default false)
    //       - Number of blocks to poll (-blocks, default 3)
    //       Parse the flags
    
    // TODO: Dial the RPC endpoint using ethclient.Dial()
    //       Note: Use Dial() not DialContext() for WebSocket support
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: If WebSocket mode (-ws):
    //       - Create a channel for headers: make(chan *types.Header)
    //       - Subscribe to new heads using client.SubscribeNewHead()
    //       - Handle subscription errors via sub.Err() channel
    //       - Loop forever, printing new headers as they arrive
    //       - Print: block number, hash, parent hash
    
    // TODO: If HTTP polling mode (default):
    //       - Fetch the latest block header using client.HeaderByNumber(ctx, nil)
    //       - Calculate the start block: latest - blocks + 1
    //       - Loop from start to latest block:
    //         * Fetch each block header using client.HeaderByNumber()
    //         * Print: block number, hash, parent hash
    //       - Note: This is the fallback when WebSocket isn't available
}
