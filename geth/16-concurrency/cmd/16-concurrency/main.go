package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "sync"
    "time"

    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - Start block number (-start)
    //       - Number of blocks to fetch (-count)
    //       - Number of worker goroutines (-workers, default 3)
    //       Parse the flags
    
    // TODO: Create a context with timeout (builds on previous modules)
    //       Use longer timeout (15 seconds) since we're fetching multiple blocks
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Create a jobs channel for distributing block numbers to workers
    //       Channel type: chan uint64
    
    // TODO: Create a WaitGroup to wait for all workers to finish
    //       Use sync.WaitGroup{}
    
    // TODO: Start worker goroutines:
    //       - Loop from 0 to workers count
    //       - For each worker:
    //         * Add 1 to WaitGroup
    //         * Start a goroutine that:
    //           - Decrements WaitGroup when done (defer wg.Done())
    //           - Loops over jobs channel (for n := range jobs)
    //           - Fetches block header using client.HeaderByNumber()
    //           - Handles errors (log but continue)
    //           - Prints worker ID, block number, and hash
    
    // TODO: Send block numbers to jobs channel:
    //       - Loop from start to start+count
    //       - Send each block number to jobs channel
    
    // TODO: Close the jobs channel (signals workers to finish)
    
    // TODO: Wait for all workers to complete using wg.Wait()
}
