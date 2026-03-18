// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "../src/SortThree.sol"; // 假设你的合约在 src 目录下

contract BankTest is Test {
    Bank public bank;
    address public owner;
    
    // 定义三个测试用户
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public user4 = makeAddr("user4");

    function setUp() public {
        // 部署合约，当前合约（BankTest）就是 owner
        bank = new Bank();
        owner = address(this);
    }

    // 1. 测试初始状态
    function test_InitialState() public {
        assertEq(bank.owner(), address(this));
    }

    // 2. 测试直接转账 (receive)
    function test_Receive() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        
        // 直接发送 ETH 给合约地址
        (bool success, ) = address(bank).call{value: 1 ether}("");
        assertTrue(success);
        
        assertEq(bank.balances(user1), 1 ether);
    }

    // 3. 测试排行榜逻辑 (重点)
    function test_LeaderboardLogic() public {
        // --- 场景 A: 三个人按顺序存钱 ---
        // User1: 10 ETH, User2: 20 ETH, User3: 30 ETH
        
        hoax(user1, 10 ether);
        bank.deposit{value: 10 ether}();

        hoax(user2, 20 ether);
        bank.deposit{value: 20 ether}();

        hoax(user3, 30 ether);
        bank.deposit{value: 30 ether}();

        // 此时榜单应该是: [User3, User2, User1]
        assertEq(bank.topUsers(0), user3);
        assertEq(bank.topUsers(1), user2);
        assertEq(bank.topUsers(2), user1);

        // --- 场景 B: User1 突然发力，反超 User2 变成第 2 名 ---
        // User1 再存 15 ETH，总计 25 ETH
        hoax(user1, 15 ether);
        bank.deposit{value: 15 ether}();

        // 此时榜单应该是: [User3, User1, User2]
        assertEq(bank.topUsers(0), user3); // 30
        assertEq(bank.topUsers(1), user1); // 25
        assertEq(bank.topUsers(2), user2); // 20

        // --- 场景 C: 一个校外新人 User4 杀入榜单第一 ---
        hoax(user4, 100 ether);
        bank.deposit{value: 100 ether}();

        // 此时榜单应该是: [User4, User3, User1]，User2 被挤出去了
        assertEq(bank.topUsers(0), user4);
        assertEq(bank.topUsers(1), user3);
        assertEq(bank.topUsers(2), user1);
    }

    // 4. 测试提款权限 (only_owner)
    function test_WithdrawPermission() public {
        // 先存点钱进去
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 5 ether}();

        // 尝试非 owner 提款，应该失败
        vm.prank(user1);
        vm.expectRevert(); // 期待下一行报错
        bank.withdraw(1 ether);

        // Owner 提款，应该成功
        uint256 balanceBefore = address(this).balance;
        bank.withdraw(1 ether);
        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter - balanceBefore, 1 ether);
    }

    // 5. 测试提款金额超过上限
    function test_WithdrawInsufficientBalance() public {
        vm.expectRevert("balance is  insufficient!");
        bank.withdraw(1 ether);
    }

    // 必须要实现 receive 才能接收从 bank 提出来的 ETH
    receive() external payable {}
}
