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

const erc20ABI = `[{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]`

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - Token address (-token)
    //       - Start block (-from, default 0)
    //       - End block (-to, default 0 means latest)
    //       Parse the flags
    
    // TODO: Validate that token address is provided
    //       Exit with usage message if missing
    
    // TODO: Create a context with timeout (builds on previous modules)
    //       Use a longer timeout (15 seconds) since filtering can take time
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Parse the ERC20 Transfer event ABI JSON string using abi.JSON()
    //       This defines the event structure: from (indexed), to (indexed), value (not indexed)
    
    // TODO: Get the Transfer event topic (event signature hash)
    //       Use parsed.Events["Transfer"].ID
    //       This is Topics[0] - the event signature hash
    
    // TODO: Build an ethereum.FilterQuery with:
    //       - FromBlock: Start block (big.NewInt(*from))
    //       - ToBlock: End block (nil for latest, or big.NewInt(*to) if specified)
    //       - Addresses: Array containing the token address
    //       - Topics: Array of topic arrays - first element should contain the Transfer topic
    
    // TODO: Fetch logs using client.FilterLogs(ctx, query)
    //       This queries all Transfer events matching the filter
    //       Handle errors appropriately
    
    // TODO: Loop through each log and decode it:
    //       - Decode the data field (value) using parsed.UnpackIntoInterface()
    //       - Extract indexed parameters from Topics:
    //         * Topics[0] = event signature (already filtered)
    //         * Topics[1] = from address (indexed)
    //         * Topics[2] = to address (indexed)
    //       - Convert topic bytes to addresses using common.BytesToAddress()
    //       - Print: block number, tx hash, from, to, value
}
