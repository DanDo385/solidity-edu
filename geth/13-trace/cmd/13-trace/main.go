package main

import (
    "context"
    "encoding/json"
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
    //       Default to "http://localhost:8545" (local node with debug API)
    //       Note: debug_traceTransaction is often disabled on public RPCs
    //       Add flags for:
    //       - RPC endpoint
    //       - Transaction hash (-tx)
    //       - Timeout duration
    //       Parse the flags
    
    // TODO: Validate that transaction hash is provided
    //       Exit with usage message if missing
    
    // TODO: Create a context with timeout (builds on previous modules)
    //       Use longer timeout (15 seconds) since tracing can be slow
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Call debug_traceTransaction using client.Client().CallContext()
    //       This is a low-level RPC call (not wrapped by ethclient)
    //       Parameters:
    //       - Context
    //       - Result variable (map[string]interface{})
    //       - Method name: "debug_traceTransaction"
    //       - Transaction hash (convert hex string to common.Hash)
    //       - Tracer options (empty map for default tracer)
    //       Handle errors appropriately
    //       Note: This requires a node with debug API enabled
    
    // TODO: Pretty-print the trace result as JSON
    //       Use json.MarshalIndent() for readable output
    //       Print transaction hash and trace result
}
