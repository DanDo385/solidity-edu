package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flag for RPC endpoint
    //       Parse the flags
    
    // TODO: Get transaction hashes from command-line arguments (flag.Args())
    //       Check if at least one hash was provided
    //       Exit with usage message if no hashes provided
    
    // TODO: Create a context with timeout (builds on previous modules)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Loop through each transaction hash:
    //       - Convert hex string to common.Hash
    //       - Fetch transaction receipt using client.TransactionReceipt()
    //       - Handle errors appropriately
    
    // TODO: Determine transaction status:
    //       - Status 1 = success (OK)
    //       - Status 0 = revert/failure (FAIL)
    //       Note: Status field was added in Byzantium fork
    
    // TODO: Print receipt information:
    //       - Transaction hash
    //       - Status (OK or FAIL)
    //       - Gas used
    //       - Number of logs emitted
    //       - Block number where transaction was included
}
