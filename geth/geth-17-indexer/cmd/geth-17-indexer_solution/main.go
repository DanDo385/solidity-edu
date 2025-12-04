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
	if defaultRPC == "" {
		defaultRPC = "https://mainnet.infura.io/v3/INFURA_RPC_URL"
	}
	rpc := flag.String("rpc", defaultRPC, "RPC endpoint")
	tokenHex := flag.String("token", "", "ERC20 token address")
	from := flag.Int64("from", 0, "start block")
	to := flag.Int64("to", 0, "end block (0=latest)")
	dbPath := flag.String("db", "transfers.db", "sqlite output")
	flag.Parse()

	if *tokenHex == "" {
		log.Fatal("usage: -token <addr> [-from N] [-to M]")
	}

	// EDUCATIONAL NOTES:
	// - Minimal indexer: fetch logs, decode Transfer, persist to sqlite.
	// - Production: add reorg handling (module 18), pagination, retries, and deduplication.
	// - Analogy: clipping Transfer entries from the public newspaper into your own filing cabinet.

	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()

	client, err := ethclient.DialContext(ctx, *rpc)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	db, err := sql.Open("sqlite", *dbPath)
	if err != nil {
		log.Fatalf("sqlite open: %v", err)
	}
	defer db.Close()
	if _, err := db.Exec(`CREATE TABLE IF NOT EXISTS transfers(block INTEGER, txhash TEXT, sender TEXT, recipient TEXT, value TEXT)`); err != nil {
		log.Fatalf("schema: %v", err)
	}

	parsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		log.Fatalf("abi: %v", err)
	}
	topic := parsed.Events["Transfer"].ID

	q := ethereum.FilterQuery{
		FromBlock: big.NewInt(*from),
		ToBlock:   nil,
		Addresses: []common.Address{common.HexToAddress(*tokenHex)},
		Topics:    [][]common.Hash{{topic}},
	}
	if *to > 0 {
		q.ToBlock = big.NewInt(*to)
	}

	logs, err := client.FilterLogs(ctx, q)
	if err != nil {
		log.Fatalf("filter: %v", err)
	}

	for _, lg := range logs {
		var data struct{ Value *big.Int }
		if err := parsed.UnpackIntoInterface(&data, "Transfer", lg.Data); err != nil {
			log.Fatalf("unpack: %v", err)
		}
		fromAddr := common.BytesToAddress(lg.Topics[1].Bytes())
		toAddr := common.BytesToAddress(lg.Topics[2].Bytes())
		if _, err := db.Exec(`INSERT INTO transfers(block, txhash, sender, recipient, value) VALUES (?, ?, ?, ?, ?)`, lg.BlockNumber, lg.TxHash.Hex(), fromAddr.Hex(), toAddr.Hex(), data.Value.String()); err != nil {
			log.Fatalf("insert: %v", err)
		}
		fmt.Printf("indexed block=%d tx=%s from=%s to=%s value=%s\n", lg.BlockNumber, lg.TxHash.Hex(), fromAddr.Hex(), toAddr.Hex(), data.Value.String())
	}

	// Commentary:
	// - This is a minimal indexer; for reorg safety, store block hash and detect mismatches (module 18).
	// - SQLite is fine for demos; production indexers use Postgres/ClickHouse.
	// Analogy: clipping Transfer entries into a local ledger for fast lookup.
}
