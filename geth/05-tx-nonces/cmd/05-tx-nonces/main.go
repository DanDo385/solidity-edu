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
    //       - Private key hex string (-priv) - WARNING: test only, never use real keys!
    //       - Timeout duration
    //       Parse the flags
    
    // TODO: Validate that recipient address and private key are provided
    //       Exit with usage message if missing
    
    // TODO: Convert recipient hex string to common.Address
    //       Convert private key hex string to *ecdsa.PrivateKey
    //       Remember to trim "0x" prefix if present
    //       Derive the sender address from the private key (builds on module 03)
    
    // TODO: Create a context with timeout (builds on modules 01-02)
    
    // TODO: Dial the RPC endpoint using ethclient.DialContext
    //       Handle connection errors
    //       Don't forget to defer client.Close()
    
    // TODO: Fetch the pending nonce for the sender address
    //       Use client.PendingNonceAt(ctx, from)
    //       This is the next nonce to use (may include pending transactions)
    
    // TODO: Fetch the suggested gas price
    //       Use client.SuggestGasPrice(ctx)
    //       This returns a recommended gas price in wei
    
    // TODO: Convert ETH amount to wei
    //       Multiply by 1e18 (10^18)
    //       Note: Using float64 is for demo only - use big.Rat for production precision!
    
    // TODO: Set gas limit to 21000 (standard ETH transfer)
    //       This is the minimum gas required for a simple transfer
    
    // TODO: Create a legacy transaction using types.NewTransaction()
    //       Parameters: nonce, to, valueWei, gasLimit, gasPrice, nil (no data)
    
    // TODO: Fetch the chain ID (builds on module 01)
    //       Required for EIP-155 replay protection
    
    // TODO: Sign the transaction using types.SignTx()
    //       Use types.NewEIP155Signer(chainID) for EIP-155 replay protection
    //       Sign with the private key
    
    // TODO: Send the signed transaction using client.SendTransaction()
    //       Handle errors appropriately
    
    // TODO: Print transaction details:
    //       - Transaction hash
    //       - Sender address
    //       - Nonce used
    //       - Recipient address
    //       - Value sent (in wei)
    //       - Gas price
}
