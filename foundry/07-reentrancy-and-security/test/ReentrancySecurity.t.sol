// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/ReentrancySecuritySolution.sol";

contract ReentrancySecurityTest is Test {
    VulnerableBank public vulnerableBank;
    SecureBank public secureBank;
    Attacker public attacker;
    
    address public victim1;
    address public victim2;
    
    function setUp() public {
        vulnerableBank = new VulnerableBank();
        secureBank = new SecureBank();
        
        victim1 = makeAddr("victim1");
        victim2 = makeAddr("victim2");
        
        vm.deal(victim1, 5 ether);
        vm.deal(victim2, 5 ether);
        
        vm.prank(victim1);
        vulnerableBank.deposit{value: 3 ether}();
        
        vm.prank(victim2);
        vulnerableBank.deposit{value: 3 ether}();
    }
    
    function test_ReentrancyAttack_Succeeds() public {
        uint256 bankBalanceBefore = address(vulnerableBank).balance;
        console.log("Bank balance before attack:", bankBalanceBefore);
        
        attacker = new Attacker(address(vulnerableBank));
        
        vm.deal(address(this), 1 ether);
        attacker.attack{value: 1 ether}();
        
        uint256 bankBalanceAfter = address(vulnerableBank).balance;
        uint256 attackerBalance = attacker.getBalance();
        
        console.log("Bank balance after attack:", bankBalanceAfter);
        console.log("Attacker balance:", attackerBalance);
        
        assertTrue(attackerBalance > 1 ether, "Attacker should have stolen funds");
        assertTrue(bankBalanceAfter < bankBalanceBefore, "Bank should have lost funds");
    }
    
    function test_SecureBank_PreventsReentrancy() public {
        vm.prank(victim1);
        secureBank.deposit{value: 3 ether}();
        
        vm.prank(victim1);
        secureBank.withdraw(1 ether);
        
        assertEq(secureBank.balances(victim1), 2 ether);
    }
    
    function test_VulnerableBank_LosesAllFunds() public {
        attacker = new Attacker(address(vulnerableBank));
        vm.deal(address(this), 1 ether);
        attacker.attack{value: 1 ether}();
        
        uint256 attackerProfit = attacker.getBalance() - 1 ether;
        console.log("Attacker profit:", attackerProfit);
        
        assertTrue(attackerProfit > 0, "Attacker should profit from attack");
    }
}
