package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "strings"
    "time"

    "github.com/ethereum/go-ethereum"
    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - Contract address (-contract)
    //       - Function name (-fn, default "name")
    //       - Timeout duration
    //       Parse the flags
    
    // TODO: Validate that contract address is provided
    //       Exit with usage message if missing
    
    // TODO: Create a context with timeout (builds on modules 01-06)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Define ERC20 ABI JSON string for view functions:
    //       - name() returns string
    //       - symbol() returns string
    //       - decimals() returns uint8
    //       - totalSupply() returns uint256
    
    // TODO: Parse the ABI JSON string using abi.JSON()
    //       This creates an ABI object for encoding/decoding
    
    // TODO: Pack the function call using parsed.Pack(fnName)
    //       This encodes the function selector and arguments
    //       For functions with no arguments, just pass the function name
    
    // TODO: Convert contract address hex string to common.Address
    
    // TODO: Create an ethereum.CallMsg with:
    //       - To: Contract address (pointer)
    //       - Data: Packed function call data
    
    // TODO: Execute the call using client.CallContract()
    //       Pass context, callMsg, and nil for latest block
    //       This simulates the transaction without persisting state
    //       Handle errors (reverts will appear as errors)
    
    // TODO: Decode the return value based on function type:
    //       - name/symbol: string
    //       - decimals: uint8
    //       - totalSupply: *big.Int
    //       Use parsed.UnpackIntoInterface() to decode
    //       Handle errors appropriately
    
    // TODO: Print the result in a readable format
}
