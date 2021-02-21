// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library DataTypes {
    struct NFTInfor {
        // the id of the nft. Represents the position in the list of the nft
        uint256 id;
        // registered by anyone
        bool isRegistered;
        // accepted by admin
        bool isAccepted;
    }

    struct SellOrder {
        //id
        uint256 sellId;
        // the address of the nft
        address nftAddress;
        // the tokenId
        uint256 tokenId;
        // seller
        address payable seller;
        // price
        uint256 price;
        // is Active to buy
        bool isActive;
        // sell time
        uint256 sellTime;
        // buyer
        address buyer;
        // buy time
        uint256 buyTime;
    }

    struct DynamicArray {
        // index to value
        mapping(uint256 => uint256) value;
        // length of array
        uint256 length;
    }
}
