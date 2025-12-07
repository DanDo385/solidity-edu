package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for RPC URL, timeout, and retry count
    //       Parse the flags
    
    // TODO: Create a context with timeout (builds on module 01)
    //       This prevents hanging on slow/broken RPCs
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Query the latest block number using client.BlockNumber(ctx)
    //       This is the cheapest operation - just returns a number
    
    // TODO: Query the network ID (legacy identifier from module 01)
    
    // TODO: Fetch the FULL latest block using client.BlockByNumber(ctx, nil)
    //       This is heavier than HeaderByNumber from module 01 - it includes transaction data
    //       Implement a retry loop: try up to (retries + 1) times
    //       Add a small delay (100ms) between retries
    //       Break out of the loop if successful
    
    // TODO: Check if the block fetch failed after all retries
    //       Log a fatal error if it did
    
    // TODO: Print a summary showing:
    //       - Network ID
    //       - Block number (from BlockNumber call)
    //       - Block number (from the fetched block - should match!)
    //       - Block hash
    //       - Parent hash
    //       - Transaction count
    //       - Gas used
}
