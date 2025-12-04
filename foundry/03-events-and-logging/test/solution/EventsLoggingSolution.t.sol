// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/solution/EventsLoggingSolution.sol";

contract EventsLoggingTest is Test {
    EventsLoggingSolution public events;
    address public user1;
    address public user2;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);

    function setUp() public {
        events = new EventsLoggingSolution();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        vm.deal(user1, 10 ether);
    }

    function test_Transfer_EmitsEvent() public {
        uint256 amount = 100;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), user1, amount);
        
        events.transfer(user1, amount);
    }

    function test_Approval_EmitsEvent() public {
        uint256 amount = 500;
        
        vm.expectEmit(true, true, false, true);
        emit Approval(address(this), user1, amount);
        
        events.approve(user1, amount);
    }

    function test_Deposit_EmitsEventWithTimestamp() public {
        uint256 amount = 1 ether;
        
        vm.expectEmit(true, false, false, false);
        emit Deposit(user1, amount, block.timestamp);
        
        vm.prank(user1);
        events.deposit{value: amount}();
    }

    function test_MultipleEvents_InSingleTransaction() public {
        vm.startPrank(address(this));
        
        events.transfer(user1, 100);
        events.approve(user2, 200);
        events.updateStatus("active");
        
        vm.stopPrank();
    }
}
