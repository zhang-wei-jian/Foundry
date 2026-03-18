// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";

contract MockTest is Test {
    MockToken public mockToken;

    function setUp() public {
        mockToken = new MockToken(address(this), address(this));
    }

    function test_Increment() public {
        mockToken.safeMint(address(this), 2);
        uint bal = mockToken.balanceOf(address(this));
        console.log(bal);
    }

    function testFuzz_SetNumber(uint256 x) public {
        // 假设我们要测试的铸造量不会导致总供应量爆炸
        // 比如限制 x 不能超过 10 亿个（考虑到 18 位小数）
        vm.assume(x < 1e27);
        mockToken.safeMint(address(this), x);
        uint bal = mockToken.balanceOf(address(this));
        console.log(bal);
    }
}
