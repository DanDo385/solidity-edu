package main

import (
    "context"
    "crypto/ecdsa"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "strings"
    "time"

    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/crypto"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // TODO: Read RPC URL from INFURA_RPC_URL environment variable
    //       Provide a default placeholder if not set
    //       Add flags for:
    //       - RPC endpoint
    //       - Recipient address (-to)
    //       - ETH amount to send (-eth)
    //       - Private key hex string (-priv) - WARNING: test only!
    //       - Max fee per gas in gwei (-maxfee, default 30)
    //       - Max priority fee per gas in gwei (-maxtip, default 2)
    //       - Timeout duration
    //       Parse the flags
    
    // TODO: Validate that recipient address and private key are provided
    //       Exit with usage message if missing
    
    // TODO: Create a context with timeout (builds on modules 01-02)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Parse private key from hex string (builds on module 03)
    //       Derive sender address from private key
    //       Convert recipient hex string to common.Address
    
    // TODO: Fetch the pending nonce for the sender address (builds on module 05)
    
    // TODO: Convert gwei to wei for gas fees
    //       1 gwei = 1,000,000,000 wei
    //       Calculate maxPriorityFeePerGas in wei
    //       Calculate maxFeePerGas in wei
    
    // TODO: Convert ETH amount to wei
    //       Multiply by 1e18 (10^18)
    //       Note: Using float64 is for demo only - use big.Rat for production precision!
    
    // TODO: Set gas limit to 21000 (standard ETH transfer)
    
    // TODO: Create an EIP-1559 dynamic fee transaction using types.NewTx()
    //       Use types.DynamicFeeTx struct with:
    //       - Nonce
    //       - GasTipCap (maxPriorityFeePerGas)
    //       - GasFeeCap (maxFeePerGas)
    //       - Gas (gas limit)
    //       - To (recipient address - use pointer)
    //       - Value (amount in wei)
    //       - Data (nil for simple transfer)
    
    // TODO: Fetch the chain ID (builds on modules 01, 05)
    
    // TODO: Sign the transaction using types.SignTx()
    //       Use types.NewLondonSigner(chainID) for EIP-1559 transactions
    //       Sign with the private key
    
    // TODO: Send the signed transaction using client.SendTransaction()
    //       Handle errors appropriately
    
    // TODO: Print transaction details:
    //       - Transaction hash
    //       - Sender address
    //       - Nonce used
    //       - Recipient address
    //       - Value sent (in wei)
    //       - Max fee per gas
    //       - Max priority fee per gas
}
