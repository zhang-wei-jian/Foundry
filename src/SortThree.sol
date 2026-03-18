// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// 这是合约bank
contract Bank {
    mapping(address => uint256) public balances; //记录函数存款的人和余额
    address public owner; //部署人

    address[3] public topUsers; // 记录前三名的地址

    // 初始化设定合约部署人控制
    constructor() {
        owner = msg.sender;
    }

    modifier only_owner() {
        // 自定义修饰符
        require(msg.sender == owner);
        _;
    }

    receive() external payable {
        // 合约接收到eth回调函数
        balances[msg.sender] += msg.value;
        _sort(msg.sender);
    }

    function _sort(address user) internal {
        // 排序

        address newAddr = user;
        address oldAddr;

        for (uint i = 0; i < 3; i++) {
            if (balances[newAddr] > balances[topUsers[0]]) {
                //新用户对比第一，不知道用户是榜单还是外人（如果是榜单升上来，他原来排名没变）
                if (newAddr == topUsers[1]) {
                    //是榜单爬上来的
                    delete topUsers[1];
                } else if (newAddr == topUsers[2]) {
                    delete topUsers[2];
                }
                //外人冲榜
                oldAddr = topUsers[0]; //保留旧榜单的人，方便去重新排列
                topUsers[0] = newAddr; //更新排行榜
                newAddr = oldAddr; //拿出上次的去对比下一次
            } else if (
                balances[newAddr] > balances[topUsers[1]] &&
                (newAddr != topUsers[0])
            ) {
                //并且不是第1
                //新用户对比第二

                if (newAddr == topUsers[2]) {
                    delete topUsers[2];
                }

                //有人冲榜
                oldAddr = topUsers[1]; //保留旧榜单的人，方便去重新排列
                topUsers[1] = newAddr; //更新排行榜
                newAddr = oldAddr; //拿出上次的去对比下一次
            } else if (
                balances[newAddr] >= balances[topUsers[2]] &&
                newAddr != topUsers[0] &&
                newAddr != topUsers[1]
            ) {
                //并且不是1或2
                //新用户对比第三

                //有人冲榜
                oldAddr = topUsers[2]; //保留旧榜单的人，方便去重新排列
                topUsers[2] = newAddr; //更新排行榜
                newAddr = oldAddr; //拿出上次的去对比下一次
            } else {
                // 不配上榜
                break;
            }
        }
    }

    function deposit() public payable {
        // 存款

        balances[msg.sender] += msg.value; // msg.value 是用户发来的 ETH 金额
        _sort(msg.sender);
    }

    function withdraw(uint256 amount) public only_owner {
        // 提款机
        // require(this.balances>= amount, "balance is not insufficient!");
        require(address(this).balance >= amount, "balance is  insufficient!");
        // payable(msg.sender).transfer(amount);
        payable(owner).transfer(amount);
    }
}

// 可以接受eth直接发送eth给合约地址，还是通过despoit函数调用
// 相当于众筹，最后记录了存储人，所有人可以把钱拿走

/*

可以通过 Metamask 等钱包直接给 Bank 合约地址存款
在 Bank 合约记录每个地址的存款金额
编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
用数组记录存款金额的前 3 名用户

*/
