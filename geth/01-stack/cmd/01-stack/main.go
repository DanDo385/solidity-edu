package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read the RPC URL from environment variable INFURA_RPC_URL
    //       If not set, use a default placeholder URL
    //       This allows users to configure their endpoint without code changes
    rpcUrl := os.Getenv("INFURA_RPC_URL")
    if rpcUrl == "" {
        rpcUrl = "https://mainnet.infura.io/v3/INFURA_RPC_URL"
    }
    // TODO: Add a flag for RPC URL with the environment variable as default
    //       Add a flag for timeout duration (default 5 seconds)
    //       Parse the flags
    // Parse flags for RPC URL and timeout, with sensible defaults
    rpcFlag := flag.String("rpc", rpcUrl, "Ethereum JSON-RPC URL")
    timeoutFlag := flag.Duration("timeout", 5*time.Second, "Timeout for RPC requests")
    flag.Parse()

    // TODO: Create a context with timeout to prevent hanging forever
    //       Remember to defer cancel() to clean up resources
    ctx, cancel := context.WithTimeout(context.Background(), *timeoutFlag)
    defer cancel()

    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors appropriately
    //       Don't forget to defer client.Close()
    
    
    // TODO: Query the chain ID (EIP-155 replay protection identifier)
    //       This tells you which network you're connected to
    
    // TODO: Query the network ID (legacy identifier, often same as chain ID)
    //       This is the older way to identify networks
    
    // TODO: Fetch the latest block header (nil means "latest")
    //       Headers are lightweight - they don't include transaction bodies
    
    // TODO: Print a summary showing:
    //       - Chain ID
    //       - Network ID  
    //       - Latest block number
    //       - Block hash
    //       - Parent hash
}
