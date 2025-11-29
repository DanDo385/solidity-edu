// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/FunctionsPayableSolution.sol";

contract DeployFunctionsPayable is Script {
    function run() external {
        // Use PRIVATE_KEY from env when broadcasting to testnet; fallback is Anvil's default
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        // Broadcast turns vm calls into signed transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the solution with a small seed balance to demo payable constructor paths
        FunctionsPayableSolution payableContract = new FunctionsPayableSolution{value: 0.1 ether}();

        console.log("FunctionsPayable deployed at:", address(payableContract));
        console.log("Owner:", payableContract.owner());
        console.log("Contract balance:", payableContract.getContractBalance());

        // End broadcast so later script steps (if added) don't accidentally send txs
        vm.stopBroadcast();
    }
}
