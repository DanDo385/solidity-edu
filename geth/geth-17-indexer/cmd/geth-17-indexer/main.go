package main

import (
    "context"
    "database/sql"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "strings"
    "time"

    _ "modernc.org/sqlite"

    "github.com/ethereum/go-ethereum"
    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/ethclient"
)

const erc20ABI = `[{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]`

func main() {
    defaultRPC := os.Getenv("INFURA_RPC_URL")
    if defaultRPC == "" { defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY" }
    rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
    tokenHex := flag.String("token", "", "ERC20 token address")
    from := flag.Int64("from", 0, "start block")
    to := flag.Int64("to", 0, "end block (0=latest)")
    dbPath := flag.String("db", "transfers.db", "sqlite output")
    flag.Parse()

    if *tokenHex == "" { log.Fatal("usage: -token <addr> [-from N] [-to M]") }

    ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
    defer cancel()

    client, err := ethclient.DialContext(ctx, *rpc)
    if err != nil { log.Fatalf("dial: %v", err) }
    defer client.Close()

    db, err := sql.Open("sqlite", *dbPath)
    if err != nil { log.Fatalf("sqlite: %v", err) }
    defer db.Close()
    db.Exec(`CREATE TABLE IF NOT EXISTS transfers(block INTEGER, txhash TEXT, sender TEXT, recipient TEXT, value TEXT)`)

    parsed, err := abi.JSON(strings.NewReader(erc20ABI))
    if err != nil { log.Fatalf("abi: %v", err) }
    topic := parsed.Events["Transfer"].ID

    q := ethereum.FilterQuery{FromBlock: big.NewInt(*from), ToBlock: nil, Addresses: []common.Address{common.HexToAddress(*tokenHex)}, Topics: [][]common.Hash{{topic}}}
    if *to > 0 { q.ToBlock = big.NewInt(*to) }

    logs, err := client.FilterLogs(ctx, q)
    if err != nil { log.Fatalf("filter: %v", err) }
    for _, lg := range logs {
        var data struct{ Value *big.Int }
        if err := parsed.UnpackIntoInterface(&data, "Transfer", lg.Data); err != nil { log.Fatalf("unpack: %v", err) }
        fromA := common.BytesToAddress(lg.Topics[1].Bytes())
        toA := common.BytesToAddress(lg.Topics[2].Bytes())
        db.Exec(`INSERT INTO transfers(block, txhash, sender, recipient, value) VALUES (?, ?, ?, ?, ?)`, lg.BlockNumber, lg.TxHash.Hex(), fromA.Hex(), toA.Hex(), data.Value.String())
        fmt.Printf("indexed block=%d tx=%s from=%s to=%s value=%s\n", lg.BlockNumber, lg.TxHash.Hex(), fromA.Hex(), toA.Hex(), data.Value.String())
    }
}
