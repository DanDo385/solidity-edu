package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - Block number (-block, -1 means latest)
    //       Parse the flags
    
    // TODO: Create a context with timeout (builds on previous modules)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Prepare block number for query
    //       If blockNum >= 0, use big.NewInt(blockNum)
    //       If blockNum < 0, use nil (latest block)
    
    // TODO: Fetch the full block using client.BlockByNumber()
    //       This includes all transactions (builds on module 02)
    //       Handle errors appropriately
    
    // TODO: Print block summary:
    //       - Block number
    //       - Block hash
    //       - Parent hash
    //       - Transaction count
    //       - Gas used
    
    // TODO: Loop through transactions and print details:
    //       - Transaction index
    //       - Transaction hash
    //       - Recipient address (to)
    //       - Value sent (in wei)
    //       - Gas price
}
