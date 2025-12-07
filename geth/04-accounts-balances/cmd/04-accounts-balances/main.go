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
    //       Add flags for RPC URL and timeout
    //       Parse the flags
    
    // TODO: Get addresses from command-line arguments (flag.Args())
    //       Check if at least one address was provided
    //       Exit with usage message if no addresses provided
    
    // TODO: Create a context with timeout (builds on modules 01-02)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Loop through each address provided:
    //       - Convert hex string to common.Address using common.HexToAddress()
    //       - Query the balance using client.BalanceAt(ctx, addr, nil)
    //         (nil means latest block)
    //       - Query the code using client.CodeAt(ctx, addr, nil)
    //       - Determine account type:
    //         * If code length > 0: Contract account
    //         * If code length == 0: EOA (Externally Owned Account)
    //       - Print address, type, and balance in wei
    //       - Handle errors for each address (don't fail on first error)
}
