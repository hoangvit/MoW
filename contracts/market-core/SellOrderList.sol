// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {SellOrderLogic} from "../libraries/logic/SellOrderLogic.sol";
import {DynamicArrayLib} from "../libraries/helpers/DynamicArrayLib.sol";

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

/**
 * @title SellOrderList contract
 * @dev The place user create sell order nft
 * - Owned by the Sun* Blockchain
 * @author Sun* Blockchain
 **/
contract SellOrderList is Initializable {
    using SafeMath for uint256;
    using SellOrderLogic for DataTypes.SellOrder;
    using DynamicArrayLib for DataTypes.DynamicArray;

    IAddressesProvider public addressesProvider;

    // all sell order
    DataTypes.SellOrder[] internal _sellOrders;

    // all available sell order
    DataTypes.DynamicArray internal _availableSellOrders;

    // all sell order of an user
    mapping(address => uint256[]) internal _sellerOrders;

    // all available sell order of an user
    mapping(address => DataTypes.DynamicArray) internal _sellerAvailableOrders;

    // all sell order of a nft address
    mapping(address => uint256[]) internal _nftOrders;

    // all available sell order of a nft address
    mapping(address => DataTypes.DynamicArray) internal _nftAvailableOrders;

    // all sell order was purchased by user
    mapping(address => uint256[]) internal _buyers;

    // nftAddress => tokenId => latest sellId
    mapping(address => mapping(uint256 => uint256)) internal _inforToSellId;

    event Initialized(address indexed provider);
    event SellOrderAdded(
        address indexed seller,
        uint256 sellId,
        address nftAddress,
        uint256 tokenId,
        uint256 price
    );
    event SellOrderDeactive(
        address indexed seller,
        uint256 sellId,
        address nftAddress,
        uint256 tokenId,
        uint256 price
    );
    event SellOrderCompleted(
        address indexed seller,
        uint256 sellId,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address buyer
    );
    event PriceChanged(
        address indexed seller,
        uint256 sellId,
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    );

    modifier onlyMarket() {
        require(
            addressesProvider.getMarket() == msg.sender,
            Errors.CALLER_NOT_MARKET
        );
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the SellOrderList contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the AddressesProvider
     **/
    function initialize(address provider) public initializer {
        addressesProvider = IAddressesProvider(provider);
        emit Initialized(provider);
    }

    /**
     * @dev add sell order to the list
     * - Can only be called by Market
     * @param nftAddress The address of nft
     * @param tokenId The id of nft
     * @param seller The address of seller
     * @param price The price
     **/
    function addSellOrder(
        address nftAddress,
        uint256 tokenId,
        address payable seller,
        uint256 price
    ) external onlyMarket {
        uint256 sellId = _sellOrders.length;
        DataTypes.SellOrder memory sellOrder = SellOrderLogic.newSellOrder(
            sellId,
            nftAddress,
            tokenId,
            seller,
            price
        );

        _inforToSellId[nftAddress][tokenId] = sellId;
        _addSellOrderToList(sellOrder);

        emit SellOrderAdded(seller, sellId, nftAddress, tokenId, price);
    }

    /**
     * @dev deactive a sell order
     * - Can only be called by Market
     * @param sellId The id of sell order
     */
    function deactiveSellOrder(uint256 sellId) external onlyMarket {
        _sellOrders[sellId].deactive();
        _removeSellOrderFromList(sellId);
        emit SellOrderDeactive(
            _sellOrders[sellId].seller,
            sellId,
            _sellOrders[sellId].nftAddress,
            _sellOrders[sellId].tokenId,
            _sellOrders[sellId].price
        );
    }

    /**
     * @dev complete sell order
     * - Can only be called by Market
     * @param sellId The id of sell order
     * @param buyer The buyer
     */
    function completeSellOrder(uint256 sellId, address buyer)
        external
        onlyMarket
    {
        _sellOrders[sellId].complete(buyer);
        _buyers[buyer].push(sellId);
        _removeSellOrderFromList(sellId);
        emit SellOrderCompleted(
            _sellOrders[sellId].seller,
            sellId,
            _sellOrders[sellId].nftAddress,
            _sellOrders[sellId].tokenId,
            _sellOrders[sellId].price,
            buyer
        );
    }

    /**
     * @dev update price of a sell order
     * - Can only be called by Market
     * @param sellId The id of sell order
     * @param newPrice The new price of sell order
     */
    function updatePrice(uint256 sellId, uint256 newPrice) external onlyMarket {
        _sellOrders[sellId].updatePrice(newPrice);
        emit PriceChanged(
            _sellOrders[sellId].seller,
            sellId,
            _sellOrders[sellId].nftAddress,
            _sellOrders[sellId].tokenId,
            newPrice
        );
    }

    /**
     * @dev get information of a sell order by id
     * @param sellId The id of sell order
     * @return imformation of sell order
     */
    function getSellOrderById(uint256 sellId)
        external
        view
        returns (DataTypes.SellOrder memory)
    {
        return _sellOrders[sellId];
    }

    /**
     * @dev get information of the sell orders by id list
     * @param idList The id list of the sell orders
     * @return imformation of the sell orders
     */
    function getSellOrderByIdList(uint256[] memory idList)
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            idList.length
        );

        for (uint256 i = 0; i < idList.length; i++) {
            result[i] = _sellOrders[idList[i]];
        }

        return result;
    }

    /**
     * @dev get information of the sell orders by id range
     * @param fromId The start id
     * @param toId The end id
     * @return imformation of the sell orders
     */
    function getSellOrderByRange(uint256 fromId, uint256 toId)
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        require(
            fromId >= 0 && toId < _sellOrders.length,
            Errors.RANGE_IS_INVALID
        );

        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            toId.sub(fromId).add(1)
        );

        for (uint256 i = fromId; i <= fromId; i++) {
            result[i] = _sellOrders[i];
        }

        return result;
    }

    /**
     * @dev get all sell order
     * @return imformation of all sell order
     */
    function getAllSellOrder()
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        return _sellOrders;
    }

    /**
     * @dev get the number of sell orders
     * @return the number of sell orders
     */
    function getNumberOfSellOrder() external view returns (uint256) {
        return _sellOrders.length;
    }

    /**
     * @dev get available sell orders
     * @return The available sell orders
     */
    function getAvailableSellOrder()
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            _availableSellOrders.length
        );

        for (uint256 i = 0; i < _availableSellOrders.length; i++) {
            result[i] = _sellOrders[_availableSellOrders.value[i]];
        }

        return result;
    }

    /**
     * @dev get IdList of available sell orders
     * @return The IdList of available sell orders
     */
    function getAvailableSellOrderIdList()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](_availableSellOrders.length);

        for (uint256 i = 0; i < _availableSellOrders.length; i++) {
            result[i] = _availableSellOrders.value[i];
        }

        return result;
    }

    /**
     * @dev get sell orders of an user
     * @return The sell orders of an user
     */
    function getAllSellOrderByUser(address user)
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            _sellerOrders[user].length
        );

        for (uint256 i = 0; i < _sellerOrders[user].length; i++) {
            result[i] = _sellOrders[_sellerOrders[user][i]];
        }
        return result;
    }

    /**
     * @dev get IdList sell orders of a user
     * @return The IdList sell orders of an user
     */
    function getAllSellOrderIdListByUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](_sellerOrders[user].length);

        for (uint256 i = 0; i < _sellerOrders[user].length; i++) {
            result[i] = _sellerOrders[user][i];
        }
        return result;
    }

    /**
     * @dev get available sell orders of a user
     * @return The available sell orders of an user
     */
    function getAvailableSellOrderByUser(address user)
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            _sellerAvailableOrders[user].length
        );
        for (uint256 i = 0; i < _sellerAvailableOrders[user].length; i++) {
            result[i] = _sellOrders[_sellerAvailableOrders[user].value[i]];
        }

        return result;
    }

    /**
     * @dev get IdList available sell orders of a user
     * @return The IdList available sell orders of an user
     */
    function getAvailableSellOrderIdListByUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](
            _sellerAvailableOrders[user].length
        );
        for (uint256 i = 0; i < _sellerAvailableOrders[user].length; i++) {
            result[i] = _sellerAvailableOrders[user].value[i];
        }

        return result;
    }

    /**
     * @dev get sell orders of a nftAddress
     * @return The sell orders of a nftAddress
     */
    function getAllSellOrderByNftAddress(address nftAddress)
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            _nftOrders[nftAddress].length
        );

        for (uint256 i = 0; i < _nftOrders[nftAddress].length; i++) {
            result[i] = _sellOrders[_nftOrders[nftAddress][i]];
        }
        return result;
    }

    /**
     * @dev get IdList sell orders of a nftAddress
     * @return The IdList sell orders of a nftAddress
     */
    function getAllSellOrderIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](_nftOrders[nftAddress].length);

        for (uint256 i = 0; i < _nftOrders[nftAddress].length; i++) {
            result[i] = _nftOrders[nftAddress][i];
        }
        return result;
    }

    /**
     * @dev get available sell orders of a nftAddress
     * @return The available sell orders of a nftAddress
     */
    function getAvailableSellOrderByNftAddress(address nftAddress)
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            _nftAvailableOrders[nftAddress].length
        );

        for (uint256 i = 0; i < _nftAvailableOrders[nftAddress].length; i++) {
            result[i] = _sellOrders[_nftAvailableOrders[nftAddress].value[i]];
        }

        return result;
    }

    /**
     * @dev get IdList available sell orders of a nftAddress
     * @return The IdList available sell orders of a nftAddress
     */
    function getAvailableSellOrderIdListByNftAddress(address nftAddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](
            _nftAvailableOrders[nftAddress].length
        );

        for (uint256 i = 0; i < _nftAvailableOrders[nftAddress].length; i++) {
            result[i] = _nftAvailableOrders[nftAddress].value[i];
        }

        return result;
    }

    /**
     * @dev get sell orders was purchased by an user
     * @return The sell orders was purchased by an user
     */
    function getBoughtByUser(address user)
        external
        view
        returns (DataTypes.SellOrder[] memory)
    {
        DataTypes.SellOrder[] memory result = new DataTypes.SellOrder[](
            _buyers[user].length
        );

        for (uint256 i = 0; i < _buyers[user].length; i++) {
            result[i] = _sellOrders[_buyers[user][i]];
        }

        return result;
    }

    /**
     * @dev get IdList sell orders was purchased by an user
     * @return The IdList sell orders was purchased by an user
     */
    function getBoughtIdListByUser(address user)
        external
        view
        returns (uint256[] memory)
    {
        return _buyers[user];
    }

    /**
     * @dev get lates sellId of a nft
     * @param nftAddress address of nft contract
     * @param tokenId tokenId of nft
     * @return found (true, false) and latest sellId
     */
    function getLatestSellId(address nftAddress, uint256 tokenId)
        external
        view
        returns (bool found, uint256 id)
    {
        uint256 sellId = _inforToSellId[nftAddress][tokenId];

        if (
            _sellOrders[sellId].nftAddress == nftAddress &&
            _sellOrders[sellId].tokenId == tokenId
        ) {
            return (true, sellId);
        } else {
            return (false, sellId);
        }
    }

    /**
     * @dev check sell order is duplicate or not
     * @param nftAddress address of nft contract
     * @param tokenId tokenId of nft
     * @param seller address of seller
     * @return found (true, false) and latest sellId
     */
    function checkDuplicate(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) external view returns (bool) {
        for (uint256 i = 0; i < _sellerAvailableOrders[seller].length; i++) {
            if (
                _sellOrders[_sellerAvailableOrders[seller].value[i]]
                    .nftAddress ==
                nftAddress &&
                _sellOrders[_sellerAvailableOrders[seller].value[i]].tokenId ==
                tokenId
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev add sell order to _sellOrders, _availableSellOrders, _sellerOrders, _sellerAvailableOrders, _nftOrders, _nftAvailableOrders
     * - internal function called inside addSellOrder() function
     * @param sellOrder sell order object
     */
    function _addSellOrderToList(DataTypes.SellOrder memory sellOrder)
        internal
    {
        uint256 sellId = _sellOrders.length;

        _sellOrders.push(sellOrder);

        _availableSellOrders.push(sellId);

        _sellerOrders[sellOrder.seller].push(sellId);

        _sellerAvailableOrders[sellOrder.seller].push(sellId);

        _nftOrders[sellOrder.nftAddress].push(sellId);

        _nftAvailableOrders[sellOrder.nftAddress].push(sellId);
    }

    /**
     * @dev remove sell order from _availableSellOrders, _sellerAvailableOrders, _nftAvailableOrders
     * - internal function called inside completeSellOrder() and deactiveSellOrder() function
     * @param sellId Id of sell order
     */
    function _removeSellOrderFromList(uint256 sellId) internal {
        DataTypes.SellOrder memory sellOrder = _sellOrders[sellId];

        _availableSellOrders.removeAtValue(sellId);

        _sellerAvailableOrders[sellOrder.seller].removeAtValue(sellId);

        _nftAvailableOrders[sellOrder.nftAddress].removeAtValue(sellId);
    }
}
