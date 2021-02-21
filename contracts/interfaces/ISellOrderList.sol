// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ISellOrderList {
    function addSellOrder(
        address nftAddress,
        uint256 tokenId,
        address payable seller,
        uint256 price
    ) external;

    function getSellOrderById(uint256 id)
        external
        view
        returns (DataTypes.SellOrder memory);

    function getSellOrderByIdList(uint256[] memory idList)
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getSellOrderByRange(uint256 fromId, uint256 toId)
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getAllSellOrder()
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getNumberOfSellOrder() external view returns (uint256);

    function getAvailableSellOrder()
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getAvailableSellOrderIdList()
        external
        view
        returns (uint256[] memory);

    function getAllSellOrderByUser(address user)
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getAllSellOrderIdListByUser(address user)
        external
        view
        returns (uint256[] memory);

    function getAvailableSellOrderByUser(address user)
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getAvailableSellOrderIdListByUser(address user)
        external
        view
        returns (uint256[] memory);

    function getAllSellOrderByNftAddress(address nftAddress)
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getAllSellOrderIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory);

    function getAvailableSellOrderByNftAddress(address nftAddress)
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function getAvailableSellOrderIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory);

    function getBoughtByUser(address user)
        external
        view
        returns (DataTypes.SellOrder[] memory);

    function deactiveSellOrder(uint256 id) external;

    function completeSellOrder(uint256 id, address buyer) external;

    function updatePrice(uint256 sellId, uint256 newPrice) external;

    function checkDuplicate(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool);
}
