// SPDX-License-Identifier: MITorder
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface INftmarket {
    function tokensReceived(
        address operator,
        uint amount,
        bytes calldata data
    ) external;
}

contract NftMarket is INftmarket {
    IERC20 public immutable token; // ERC20 token address
    IERC721 public immutable nft; // ERC721 token address

    using SafeERC20 for IERC20;

    struct Order {
        address owner;
        uint money;
    }

    mapping(uint => Order) public nftOwner; // 存储NFT的拥有者

    constructor(address _token, address _nft) {
        token = IERC20(_token);
        nft = IERC721(_nft);
    }

    // 上架nft，我想采用无托管模式，省略nft发送给合约，合约再发送给购买人，这样很浪费gas，缺点是用户自己发走了
    // 解决方法：1前端检查余额，2后端扫链
    //id NFT的id，money 售卖的金额
    function list(uint _id, uint _money) public {
        require(nft.ownerOf(_id) == msg.sender, "you not have this NFT");
        nftOwner[_id].owner = msg.sender;
        nftOwner[_id].money = _money;
    }

    // 买家买东西还得表示自己支付多少钱，这是为了防止三明治攻击。有人看到购买临时修改价格
    function _buyNFT(address operator, uint _id, uint _money) internal {
        // 使用内存临时存储，避免下文频繁读取合约变量gas
        Order memory orderMemory = nftOwner[_id];

        require(_money >= orderMemory.money, " not enough pay money");
        require(
            nft.ownerOf(_id) == orderMemory.owner,
            "NFT owner not have this NFT"
        );
        // 当前合约是否可以转走NFT
        require(
            nft.getApproved(_id) == address(this) ||
                nft.isApprovedForAll(orderMemory.owner, address(this)),
            "you not have this NFT this approve contract"
        );
        // token是否足够
        require(
            token.balanceOf(operator) >= orderMemory.money,
            "you not have this NFT this approve contract"
        );

        delete nftOwner[_id];

        nft.safeTransferFrom(orderMemory.owner, operator, _id);
        token.safeTransferFrom(operator, orderMemory.owner, orderMemory.money);
    }

    // 买家买东西还得表示自己支付多少钱，这是为了防止三明治攻击。有人看到购买临时修改价格
      //id NFT的id，money, 花多少钱买
    function buyNFT(uint _id, uint _money) public {
        _buyNFT(msg.sender, _id, _money);
    }

    // 自定义实现erc20触发的回调函数，后来发现ERC1363居然和我思路一样，我重新写一个1363规范的
    function tokensReceived(
        address operator,
        uint amount,
        bytes calldata data
    ) external {
        require(msg.sender == address(token), "Scammer go away!");
        uint _id = abi.decode(data, (uint256));
        _buyNFT(operator, _id, amount);
    }

    //ERC1363规范 回调函数
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        require(msg.sender == address(token), "Scammer go away!");
        uint _id = abi.decode(data, (uint256));
        _buyNFT(owner, _id, value);

        return this.onApprovalReceived.selector;
    }
}

/*

发行一个ERC72IToken(用自己的名字）
·铸造几个NFT，在测试网上发行，在Opensea上查看
编写一个市场合约：使用自己发行的ERC20Token来买卖NFT：
·NFT持有者可上架NFT(list设置价格多少个TOKEN购买NFT）
·编写购买NFT方法 buyNFT(uint tokenID,uint amount)，转入对应的TOKEN，获取对应的NFT



编写一个简单的 NFTMarket 合约，使用自己发行的ERC20 扩展 Token 来买卖 NFT， NFTMarket 的函数有：

list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买。

buyNFT() : 普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。

实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能(注意扩展的转账需要添加一个额外数据参数)。

。pro 需要实现erc20带1363并且market支持1363，用foundry测试
*/
