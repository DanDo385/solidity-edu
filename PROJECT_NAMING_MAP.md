# Project Naming Standardization Map

> **Mapping of project numbers to descriptive names for file standardization**

This document maps each project number to its descriptive name for consistent file naming across all 50 projects.

## Naming Convention

All files should follow this pattern:
- **Contract**: `[DescriptiveName].sol` (e.g., `SafeETHTransfer.sol`)
- **Solution**: `[DescriptiveName]Solution.sol` (e.g., `SafeETHTransferSolution.sol`)
- **Test**: `[DescriptiveName].t.sol` (e.g., `SafeETHTransfer.t.sol`)
- **Script**: `Deploy[DescriptiveName].s.sol` (e.g., `DeploySafeETHTransfer.s.sol`)

## Project Mapping

| Project # | Current Name | Descriptive Name | Status |
|-----------|-------------|-----------------|--------|
| 01 | DatatypesStorage | DatatypesStorage | ✅ Already correct |
| 02 | FunctionsPayable | FunctionsPayable | ✅ Already correct |
| 03 | EventsLogging | EventsLogging | ✅ Already correct |
| 04 | ModifiersRestrictions | ModifiersRestrictions | ✅ Already correct |
| 05 | ErrorsReverts | ErrorsReverts | ✅ Already correct |
| 06 | MappingsArraysGas | MappingsArraysGas | ✅ Already correct |
| 07 | ReentrancySecurity | ReentrancySecurity | ✅ Already correct |
| 08 | ERC20Token | ERC20Token | ✅ Already correct |
| 09 | ERC721NFT | ERC721NFT | ✅ Already correct |
| 10 | UpgradeableProxy | UpgradeableProxy | ✅ Already correct |
| 11 | ERC4626Vault | ERC4626Vault | ⚠️ Check naming |
| 12 | Project12 | SafeETHTransfer | ✅ Renamed |
| 13 | Project13 | BlockTimeLogic | ⏳ To rename |
| 14 | ABIEncoding | ABIEncoding | ✅ Already correct |
| 15 | Project15 | LowLevelCalls | ⏳ To rename |
| 16 | Project16 | ContractFactory | ⏳ To rename |
| 17 | Project17 | MinimalProxy | ⏳ To rename |
| 18 | Project18 | ChainlinkOracle | ⏳ To rename |
| 19 | Project19 | SignedMessages | ⏳ To rename |
| 20 | Project20 | DepositWithdraw | ⏳ To rename |
| 21 | Project21 | ERC20FromScratch | ⏳ To rename |
| 22 | Project22 | ERC20OpenZeppelin | ⏳ To rename |
| 23 | Project23 | ERC20Permit | ⏳ To rename |
| 24 | Project24 | ERC721FromScratch | ⏳ To rename |
| 25 | Project25 | ERC721AOptimized | ⏳ To rename |
| 26 | Project26 | ERC1155MultiToken | ⏳ To rename |
| 27 | Project27 | SoulboundTokens | ⏳ To rename |
| 28 | Project28 | ERC2981Royalties | ⏳ To rename |
| 29 | Project29 | MerkleAllowlist | ⏳ To rename |
| 30 | Project30 | OnChainSVG | ⏳ To rename |
| 31 | Project31 | ReentrancyLab | ⏳ To rename |
| 32 | Project32 | OverflowLab | ⏳ To rename |
| 33 | Project33 | MEVFrontrunning | ⏳ To rename |
| 34 | Project34 | OracleManipulation | ⏳ To rename |
| 35 | Project35 | DelegatecallCorruption | ⏳ To rename |
| 36 | Project36 | AccessControlBugs | ⏳ To rename |
| 37 | Project37 | GasDoSAttacks | ⏳ To rename |
| 38 | Project38 | SignatureReplay | ⏳ To rename |
| 39 | Project39 | GovernanceAttack | ⏳ To rename |
| 40 | Project40 | MultiSigWallet | ⏳ To rename |
| 41 | Project41 | ERC4626BaseVault | ⏳ To rename |
| 42 | Project42 | VaultPrecision | ⏳ To rename |
| 43 | Project43 | YieldVault | ⏳ To rename |
| 44 | Project44 | InflationAttack | ⏳ To rename |
| 45 | Project45 | MultiAssetVault | ⏳ To rename |
| 46 | Project46 | VaultInsolvency | ⏳ To rename |
| 47 | Project47 | VaultOracle | ⏳ To rename |
| 48 | Project48 | MetaVault | ⏳ To rename |
| 49 | Project49 | LeverageVault | ⏳ To rename |
| 50 | Project50 | DeFiCapstone | ⏳ To rename |

## Script Naming Standardization

Projects 1-11 need script names updated:
- Current: `Deploy.s.sol`
- Target: `Deploy[ContractName].s.sol`

Example:
- `01-datatypes-and-storage/script/Deploy.s.sol` → `DeployDatatypesStorage.s.sol`

## Implementation Notes

1. **Rename files** using the mapping above
2. **Update imports** in all test files and scripts
3. **Update README.md** files to reflect new names
4. **Update any references** in documentation

## Automated Renaming Script

To rename all projects systematically:

```bash
# Example for project 12 (already done)
cd 12-safe-eth-transfer
mv src/Project12.sol src/SafeETHTransfer.sol
mv src/solution/Project12Solution.sol src/solution/SafeETHTransferSolution.sol
mv test/Project12.t.sol test/SafeETHTransfer.t.sol
mv script/DeployProject12.s.sol script/DeploySafeETHTransfer.s.sol

# Then update imports in all files
# Then update README.md references
```

## Status Legend

- ✅ Already correct - No changes needed
- ✅ Renamed - Completed
- ⏳ To rename - Pending
- ⚠️ Check naming - Verify current state
