// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/solution/EventsLoggingSolution.sol";

contract DeployEventsLogging is Script {
    function run() external {
        // PRIVATE_KEY env var preferred for live networks; default is Anvil first account
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        // Begin broadcasting signed transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the fully built solution (students implement src/ and compare)
        EventsLoggingSolution eventsContract = new EventsLoggingSolution();
        
        console.log("EventsLogging deployed at:", address(eventsContract));
        console.log("Owner:", eventsContract.owner());
        
        // Close broadcast session
        vm.stopBroadcast();
    }
}
