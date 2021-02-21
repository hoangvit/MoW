// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {DataTypes} from "../types/DataTypes.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

library SellOrderLogic {
    using SafeMath for uint256;

    /**
     * @dev create a sell order object
     * @param sellId The id of sell order
     * @param nftAddress The  address of nft
     * @param tokenId The tokenId of nft
     * @param seller The seller
     * @param price The price
     **/
    function newSellOrder(
        uint256 sellId,
        address nftAddress,
        uint256 tokenId,
        address payable seller,
        uint256 price
    ) internal view returns (DataTypes.SellOrder memory) {
        return
            DataTypes.SellOrder({
                sellId: sellId,
                nftAddress: nftAddress,
                tokenId: tokenId,
                seller: seller,
                price: price,
                isActive: true,
                sellTime: block.timestamp,
                buyer: address(0),
                buyTime: 0
            });
    }

    /**
     * @dev deactive a sell order
     * @param sellOrder sell order object
     **/
    function deactive(DataTypes.SellOrder storage sellOrder) internal {
        sellOrder.isActive = false;
    }

    /**
     * @dev complete a sell order
     * @param sellOrder sell order object
     * @param buyer address of buyer
     **/
    function complete(DataTypes.SellOrder storage sellOrder, address buyer)
        internal
    {
        sellOrder.isActive = false;
        sellOrder.buyTime = block.timestamp;
        sellOrder.buyer = buyer;
    }

    /**
     * @dev update price of a sell order
     * @param sellOrder sell order object
     * @param newPrice new price of the sell order
     **/
    function updatePrice(
        DataTypes.SellOrder storage sellOrder,
        uint256 newPrice
    ) internal {
        sellOrder.price = newPrice;
    }
}
