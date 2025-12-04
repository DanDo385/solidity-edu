package main

import (
    "context"
    "flag"
    "fmt"
    "log"
    "math/big"
    "os"
    "strconv"
    "strings"
    "time"

    "github.com/ethereum/go-ethereum"
    "github.com/ethereum/go-ethereum/accounts/abi"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/core/types"
    "github.com/ethereum/go-ethereum/ethclient"
)

// EDUCATIONAL NOTES:
// - This is the capstone: stitches status, block/tx lookup, and event decoding into one CLI.
// - Reuses modules: 01/02 (RPC), 09 (events), 14 (block explorer), 15 (receipts).
// - Analogy: Swiss Army knife for everyday node ops—one handle, many blades.
// - CPU analogy: status = reading CPU registers; block/tx = reading instruction log; events = reading syscall log.

func dial(ctx context.Context, url string) (*ethclient.Client, error) {
	return ethclient.DialContext(ctx, url)
}

func cmdStatus(ctx context.Context, c *ethclient.Client) error {
	head, err := c.HeaderByNumber(ctx, nil)
	if err != nil {
		return fmt.Errorf("head: %w", err)
	}
	netID, err := c.NetworkID(ctx)
	if err != nil {
		return fmt.Errorf("net: %w", err)
	}
	fmt.Printf("status net=%s block=%d hash=%s\n", netID.String(), head.Number.Uint64(), head.Hash())
	return nil
}

func cmdBlock(ctx context.Context, c *ethclient.Client, num uint64) error {
	blk, err := c.BlockByNumber(ctx, new(big.Int).SetUint64(num))
	if err != nil {
		return fmt.Errorf("block: %w", err)
	}
	fmt.Printf("block %d hash=%s txs=%d gasUsed=%d\n", blk.NumberU64(), blk.Hash(), len(blk.Transactions()), blk.GasUsed())
	for _, tx := range blk.Transactions() {
		fmt.Printf("  tx %s to=%v value=%s\n", tx.Hash(), tx.To(), tx.Value())
	}
	return nil
}

func cmdTx(ctx context.Context, c *ethclient.Client, h common.Hash) error {
	tx, pending, err := c.TransactionByHash(ctx, h)
	if err != nil {
		return fmt.Errorf("tx: %w", err)
	}
	receipt, _ := c.TransactionReceipt(ctx, h)
	fmt.Printf("tx %s pending=%v to=%v value=%s\n", h, pending, tx.To(), tx.Value())
	if receipt != nil {
		fmt.Printf("  status=%d gasUsed=%d logs=%d block=%d\n", receipt.Status, receipt.GasUsed, len(receipt.Logs), receipt.BlockNumber.Uint64())
	}
	return nil
}

func cmdEvents(ctx context.Context, c *ethclient.Client, addr common.Address, from, to *big.Int) error {
	// Minimal Transfer event decoder for ERC20.
	const erc20ABI = `[{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]`
	parsed, err := abi.JSON(strings.NewReader(erc20ABI))
	if err != nil {
		return err
	}
	topic := parsed.Events["Transfer"].ID
	q := ethereum.FilterQuery{FromBlock: from, ToBlock: to, Addresses: []common.Address{addr}, Topics: [][]common.Hash{{topic}}}
	logs, err := c.FilterLogs(ctx, q)
	if err != nil {
		return err
	}
	for _, lg := range logs {
		var data struct{ Value *big.Int }
		if err := parsed.UnpackIntoInterface(&data, "Transfer", lg.Data); err != nil {
			return err
		}
		fromA := common.BytesToAddress(lg.Topics[1].Bytes())
		toA := common.BytesToAddress(lg.Topics[2].Bytes())
		fmt.Printf("Transfer block=%d from=%s to=%s value=%s\n", lg.BlockNumber, fromA.Hex(), toA.Hex(), data.Value.String())
	}
	return nil
}

func main() {
defaultRPC := os.Getenv("INFURA_RPC_URL")
if defaultRPC == "" {
    defaultRPC = "https://mainnet.infura.io/v3/YOUR_KEY"
}
	rpcFlag := flag.String("rpc", defaultRPC, "RPC URL")
	timeout := flag.Duration("timeout", 10*time.Second, "timeout")
	flag.Parse()

	if len(flag.Args()) == 0 {
		log.Fatal("usage: toolbox <status|block|tx|events> ...")
	}
	cmd := flag.Arg(0)

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	client, err := dial(ctx, *rpcFlag)
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer client.Close()

	switch cmd {
	case "status":
		if err := cmdStatus(ctx, client); err != nil {
			log.Fatal(err)
		}
	case "block":
		if len(flag.Args()) < 2 {
			log.Fatal("block <number>")
		}
		n, _ := strconv.ParseUint(flag.Arg(1), 10, 64)
		if err := cmdBlock(ctx, client, n); err != nil {
			log.Fatal(err)
		}
	case "tx":
		if len(flag.Args()) < 2 {
			log.Fatal("tx <hash>")
		}
		h := common.HexToHash(flag.Arg(1))
		if err := cmdTx(ctx, client, h); err != nil {
			log.Fatal(err)
		}
	case "events":
		if len(flag.Args()) < 4 {
			log.Fatal("events <tokenAddr> <fromBlock> <toBlock>")
		}
		token := common.HexToAddress(flag.Arg(1))
		from, _ := new(big.Int).SetString(flag.Arg(2), 10)
		to, _ := new(big.Int).SetString(flag.Arg(3), 10)
		if err := cmdEvents(ctx, client, token, from, to); err != nil {
			log.Fatal(err)
		}
	default:
		log.Fatalf("unknown subcommand: %s", cmd)
	}

	// Commentary:
	// - Toolbox stitches together earlier modules: status, block/tx lookup, event decoding.
	// - Extend with mempool peek, index summary, or health checks as exercises.
	// Analogy: Swiss Army knife for everyday node interactions.
	_ = types.Header{}
}
