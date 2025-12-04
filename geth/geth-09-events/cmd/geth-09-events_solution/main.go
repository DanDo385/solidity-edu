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
    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/ethclient"
)

const erc20ABI = `[{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]`

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" {
        defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
    }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    tokenHex := flag.String("token", "", "ERC20 token address")
    fromBlock := flag.Int64("from", 0, "start block")
    toBlock := flag.Int64("to", 0, "end block (0=latest)")
    flag.Parse()

    if *tokenHex == "" {
        log.Fatal("usage: -token <addr> [-from N] [-to M]")
    }

    ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil {
        log.Fatalf("dial: %v", err)
    }
    defer client.Close()

    token := common.HexToAddress(*tokenHex)
    parsed, err := abi.JSON(strings.NewReader(erc20ABI))
    if err != nil {
        log.Fatalf("abi: %v", err)
    }
    transferID := parsed.Events["Transfer"].ID

    q := ethereum.FilterQuery{
        FromBlock: big.NewInt(*fromBlock),
        ToBlock:   nil,
        Addresses: []common.Address{token},
        Topics:    [][]common.Hash{{transferID}},
    }
    if *toBlock > 0 {
        q.ToBlock = big.NewInt(*toBlock)
    }

    logs, err := client.FilterLogs(ctx, q)
    if err != nil {
        log.Fatalf("filter: %v", err)
    }

    for _, lg := range logs {
        // Decode indexed and data fields.
        from := common.BytesToAddress(lg.Topics[1].Bytes())
        to := common.BytesToAddress(lg.Topics[2].Bytes())
        var data struct {
            Value *big.Int
        }
        if err := parsed.UnpackIntoInterface(&data, "Transfer", lg.Data); err != nil {
            log.Fatalf("unpack: %v", err)
        }
        fmt.Printf("block=%d tx=%s from=%s to=%s value=%s\n", lg.BlockNumber, lg.TxHash, from.Hex(), to.Hex(), data.Value.String())
    }

    // Commentary / fun facts:
    // - Topics[0] is the event signature hash; Topics[1..] hold indexed params.
    // - Data holds non-indexed params packed per ABI.
    // - Logs live in the receipt trie; bloom filters in block headers accelerate topic searches.
    // - For large ranges, paginate to avoid provider limits and to handle reorgs gracefully.
    // Analogy: each Transfer log is a newspaper clipping; topics are the bold headlines.
    _ = types.Log{}
}
