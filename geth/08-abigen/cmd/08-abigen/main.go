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

    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/accounts/abi/bind"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

const erc20ABI = `[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"type":"function"},{"constant":true,"inputs":[{"name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"type":"function"}]`

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - Token address (-token)
    //       - Optional holder address (-holder)
    //       - Timeout duration
    //       Parse the flags
    
    // TODO: Validate that token address is provided
    //       Exit with usage message if missing
    
    // TODO: Create a context with timeout (builds on previous modules)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Parse the ERC20 ABI JSON string using abi.JSON()
    //       This is the same ABI from module 07, but now we'll use typed bindings
    
    // TODO: Convert token address hex string to common.Address
    
    // TODO: Create a BoundContract using bind.NewBoundContract()
    //       Parameters: address, parsed ABI, client (for calls), client (for transactions), client (for events)
    //       This creates a typed contract binding that handles encoding/decoding automatically
    
    // TODO: Call contract functions using typed methods:
    //       - bound.Call() for view functions (name, symbol, decimals)
    //       - Use bind.CallOpts{Context: ctx} for call options
    //       - Pass output variables by reference (e.g., &name, &symbol, &decimals)
    //       - Handle errors appropriately
    
    // TODO: Print token information (name, symbol, decimals)
    
    // TODO: If holder address is provided:
    //       - Convert holder hex string to common.Address
    //       - Call balanceOf(holder) using bound.Call()
    //       - Print the balance
}
