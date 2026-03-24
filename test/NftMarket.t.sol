// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {Test, console} from "forge-std/Test.sol";

import {MockToken} from "../src/MockToken.sol";
import {MockNFT} from "../src/MockNFT.sol";

import {NftMarket} from "../src/NftMarket.sol";

contract NftMarketTest is Test {
    MockNFT public mockNFT;
    MockToken public mockToken;
    NftMarket public nftMarket;

    address alice = makeAddr("alice"); // token user
    address jack = makeAddr("jack"); // nft user

    function setUp() public {
        mockToken = new MockToken(address(this), address(this));

        mockNFT = new MockNFT(address(this));

        nftMarket = new NftMarket(address(mockToken), address(mockNFT));

        // 注意：这虽然看起来是 ether 单位，但本质上它就是个 10^18 的乘法器
        // 在 Foundry 里写起来极其丝滑
        mockToken.safeMint(address(alice), 999 ether);

        uint bal = mockToken.balanceOf(address(alice));
        console.log("jack ERC20 money sum", bal);

        mockNFT.safeMint(jack, "https://alice.json"); //因为nft有测试mini给的是合约账户会调用他的函数，这里使用alice

        mockNFT.safeMint(jack, "https://alice2.json"); //因为nft有测试mini给的是合约账户会调用他的函数，这里使用alice

        uint bl = mockNFT.balanceOf(jack);
        console.log("jack nft sum is", bl);
    }

    function test_name() public view {
        console.log("name is = ", mockNFT.name(), address(mockNFT));
        console.log("name is = ", mockToken.name(), address(mockToken));
    }

    function test_List() public {
        _List();
    }

    function test_ListAndBuyNft() public {
        uint256 nftId = 1;
        uint256 price = 888 ether;

        vm.prank(jack);
        mockNFT.approve(address(nftMarket), nftId);
        _List();

        vm.prank(alice);
        mockToken.approve(address(nftMarket), price);
        _BuyNft();

        uint bal = mockToken.balanceOf(address(jack));
        console.log("jack ERC20 money sum", bal);

        uint bl = mockNFT.balanceOf(alice);
        console.log("alice nft sum is", bl);
    }

    function test_ListAndBuyNft1363() public {
        uint256 nftId = 1;
        uint256 price = 888 ether;

        vm.prank(jack);
        mockNFT.approve(address(nftMarket), nftId);
        _List();

        vm.prank(alice);
        // mockToken.approve(address(nftMarket), price);
        // _BuyNft();
        mockToken.approveAndCall(address(nftMarket), price, abi.encode(nftId));

        uint bal = mockToken.balanceOf(address(jack));
        console.log("jack ERC20 money sum", bal);

        uint bl = mockNFT.balanceOf(alice);
        console.log("alice nft sum is", bl);
    }

    // 测试上架功能
    function _List() internal {
        uint256 nftId = 1;
        uint256 price = 888 ether;

        // address bl = mockNFT.ownerOf(nftId);
        // console.log(jack,"jack address", bl);

        vm.prank(jack);
        nftMarket.list(nftId, price);

        // 1. 调用自动生成的 Getter 函数获取结构体成员
        // 注意：如果有多个成员，它们会按顺序返回
        (address actualOwner, uint256 actualPrice) = nftMarket.nftOwner(nftId);

        // 2. 打印（虽然麻烦，但只能一个一个打）
        console.log("Stored Owner:", actualOwner);
        console.log("Stored Price:", actualPrice);

        // 3. 断言（这是测试的核心！只要断言过了，就说明上架成功了）
        assertEq(actualOwner, jack, "Owner should be Jack");
        assertEq(actualPrice, price, "Price should match");
    }

    //alice买走了jack的nft。查询jack得到多少token，和alice有没有得到nft
    function _BuyNft() internal {
        uint256 nftId = 1;
        uint256 price = 888 ether;

        vm.prank(alice);
        nftMarket.buyNFT(nftId, price);
    }
}
