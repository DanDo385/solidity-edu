// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/MappingsArraysGasSolution.sol";

contract MappingsArraysGasTest is Test {
    MappingsArraysGasSolution public mappings;
    
    function setUp() public {
        mappings = new MappingsArraysGasSolution();
    }
    
    function test_AddUser_Works() public {
        address user = makeAddr("user1");
        mappings.addUser(user);
        assertTrue(mappings.isUser(user));
    }
    
    function test_SetBalance_UpdatesTotalBalance() public {
        address user = makeAddr("user1");
        mappings.setBalance(user, 1000);
        assertEq(mappings.getTotalBalance(), 1000);
    }
    
    function test_Gas_IterationVsTracking() public {
        for (uint i = 0; i < 10; i++) {
            mappings.addUser(address(uint160(i + 1)));
            mappings.setBalance(address(uint160(i + 1)), 100);
        }
        
        uint256 gasBefore = gasleft();
        mappings.sumAllBalances();
        uint256 iterationGas = gasBefore - gasleft();
        
        gasBefore = gasleft();
        mappings.getTotalBalance();
        uint256 trackingGas = gasBefore - gasleft();
        
        emit log_named_uint("Iteration gas", iterationGas);
        emit log_named_uint("Tracking gas", trackingGas);
        assertTrue(trackingGas < iterationGas, "Tracking should be cheaper");
    }
}
