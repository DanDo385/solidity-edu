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
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - Account address (-account)
    //       - Optional storage slot (-slot, default 0)
    //       - Optional block number (-block, -1 means latest)
    //       - Timeout duration
    //       Parse the flags
    
    // TODO: Validate that account address is provided
    //       Exit with usage message if missing
    
    // TODO: Create a context with timeout (builds on previous modules)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Prepare storage slots array for proof request
    //       If slot is provided, convert to hex string and add to array
    //       Format: "0x..." (hex-encoded slot number)
    
    // TODO: Prepare block number for proof request
    //       If block >= 0, use big.NewInt(block)
    //       If block < 0, use nil (latest block)
    
    // TODO: Call client.GetProof() to fetch Merkle-Patricia trie proof
    //       Parameters: context, account address, storage slots array, block number
    //       This calls eth_getProof JSON-RPC method
    //       Handle errors appropriately
    //       Note: Some RPC providers may disable this endpoint
    
    // TODO: Print account proof information:
    //       - Balance
    //       - Nonce
    //       - CodeHash
    //       - StorageHash
    //       - Number of account proof nodes
    
    // TODO: If storage proof exists:
    //       - Print storage slot key
    //       - Print storage slot value
    //       - Print number of storage proof nodes
}
