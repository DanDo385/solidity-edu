package main

import (
    "crypto/ecdsa"
    "flag"
    "fmt"
    "log"
    "os"
    "path/filepath"

    "github.com/ethereum/go-ethereum/accounts/keystore"
    "github.com/ethereum/go-ethereum/crypto"
)

func main() {
    outDir := flag.String("out", "./keystore-demo", "directory to store keystore file")
    pass := flag.String("pass", "changeit", "keystore passphrase (demo only)")
    flag.Parse()

    priv, err := crypto.GenerateKey()
    if err != nil {
        log.Fatalf("generate key: %v", err)
    }
    pub := priv.Public().(*ecdsa.PublicKey)
    addr := crypto.PubkeyToAddress(*pub)
    fmt.Printf("Generated key address=%s\n", addr.Hex())

    if err := os.MkdirAll(*outDir, 0o700); err != nil {
        log.Fatalf("mkdir: %v", err)
    }
    ks := keystore.NewKeyStore(*outDir, keystore.StandardScryptN, keystore.StandardScryptP)
    account, err := ks.ImportECDSA(priv, *pass)
    if err != nil {
        log.Fatalf("keystore import: %v", err)
    }
    fmt.Printf("Keystore written at %s\n", filepath.Join(*outDir, filepath.Base(account.URL.Path)))
}
