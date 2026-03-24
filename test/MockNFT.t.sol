// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockNFT} from "../src/MockNFT.sol";

contract MockNFTTest is Test {
    MockNFT public mockNFT;
    address alice = makeAddr("alice");

    function setUp() public {
        
        mockNFT = new MockNFT(address(this));

        mockNFT.safeMint(alice, "https://alice.json"); //因为nft有测试mini给的是合约账户会调用他的函数，这里使用alice

    }

    function test_GetName() public {
        string memory bal = mockNFT.name();
        console.log("name is = ", bal);
    }

    function test_Minit() public {
        // mockNFT.safeMint(address(this), "https://game.example/item-id-8u5h2m.json");

        // vm.prank(alice); // 告诉底层引擎：下一行调用的 msg.sender 要假装成 alice

        uint id = mockNFT.balanceOf(alice);

        console.log("new user address the id is = ", id);
    }

    //测试当前调用者是eoa还是合约账户
    function test_ThisAddressIsContract() public {
        console.log(alice.code.length, "alice address are contract?");
        console.log(address(this).code.length, "this address are contract?");
    }

    function test_GetUrl() public {
        string memory url = mockNFT.tokenURI(0);

        console.log("alice url is = ", url);
    }
}
