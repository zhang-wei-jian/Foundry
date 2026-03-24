// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1363} from "@openzeppelin/contracts/token/ERC20/extensions/ERC1363.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockToken is ERC20, ERC1363, ERC20Permit, Ownable {
    constructor(
        address recipient,
        address initialOwner
    )
        ERC20("MockToken", "MOCK")
        ERC20Permit("MockToken")
        Ownable(initialOwner)
    {
        _mint(recipient, 1000000 * 10 ** decimals());
    }

    function safeMint(address recipient, uint value) public onlyOwner {
        _mint(recipient, value * 10 ** decimals());
    }

    // 转账 并且触发回调函数 ,1363实现过，我就不写了ERC1363.approveAndCall
    // function approveWithCallback(
    //     address to,
    //     uint amount,
    //     bytes calldata data
    // ) public {
    //     // _transfer(msg.sender,to,amount);
    //     _approve(msg.sender, to, amount);

    //     if (to.code.length > 0) {
    //         INftmarket(to).tokensReceived(msg.sender, amount, data);
    //     }
    // }
}
