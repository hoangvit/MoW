// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {INFTList} from "../interfaces/INFTList.sol";
import {ISellOrderList} from "../interfaces/ISellOrderList.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title NFTList contract
 * @dev The registrar addresses the NFTs so they can be traded on the Market
 * - Acting as a place to register, the contract owner registers and the admin accepts
 * - Owned by the Sun* Blockchain
 * @author Sun* Blockchain
 **/
contract Market is Initializable, ReentrancyGuard {
    IAddressesProvider public addressesProvider;
    INFTList public nftList;
    ISellOrderList public sellOrderList;
    IVault public vault;

    uint256 internal feeNumerator;
    uint256 internal feeDenominator;
    uint256 internal constant SAFE_NUMBER = 10 ^ 12;

    event Initialized(
        address indexed provider,
        uint256 numerator,
        uint256 denominator
    );

    event FeeUpdated(uint256 numerator, uint256 denominator);

    modifier onlyMarketAdmin() {
        require(
            addressesProvider.getAdmin() == msg.sender,
            Errors.CALLER_NOT_MARKET_ADMIN
        );
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the Market contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of AddressesProvider
     * @param numerator The fee numerator
     * @param denominator The fee of denominator
     **/
    function initialize(
        address provider,
        uint256 numerator,
        uint256 denominator
    ) public initializer {
        require(
            denominator >= numerator,
            Errors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR
        );
        addressesProvider = IAddressesProvider(provider);
        nftList = INFTList(addressesProvider.getNFTList());
        sellOrderList = ISellOrderList(addressesProvider.getSellOrderList());
        vault = IVault(addressesProvider.getVault());
        feeNumerator = numerator;
        feeDenominator = denominator;
        emit Initialized(provider, numerator, denominator);
    }

    /**
     * @dev Update fee
     * - Can only be called by admin
     * @param numerator The fee numerator
     * @param denominator The fee denominator
     **/
    function updateFee(uint256 numerator, uint256 denominator)
        external
        onlyMarketAdmin
    {
        require(
            denominator >= numerator,
            Errors.DEMONINATOR_NOT_GREATER_THAN_NUMERATOR
        );
        feeNumerator = numerator;
        feeDenominator = denominator;
        emit FeeUpdated(numerator, denominator);
    }

    /**
     * @dev Create a sell order
     * - Can be called at anyone
     * @param nftAddress The address of the NFT contract
     * @param tokenId tokenId of nft
     * @param price price offered by the seller
     **/
    function createSellOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant {
        require(nftList.isAcceptedNFT(nftAddress), Errors.NFT_NOT_ACCEPTED);
        require(
            IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
            Errors.CALLER_NOT_NFT_OWNER
        );
        require(
            IERC721(nftAddress).getApproved(tokenId) == address(this),
            Errors.NFT_NOT_APPROVED_FOR_MARKET
        );
        require(
            !sellOrderList.checkDuplicate(nftAddress, tokenId, msg.sender),
            Errors.SELL_ORDER_DUPLICATE
        );
        sellOrderList.addSellOrder(nftAddress, tokenId, msg.sender, price);
    }

    /**
     * @dev Cancle a sell order
     * - Can only be called by seller
     * @param id The id of sell order
     **/
    function cancleSellOrder(uint256 id) external nonReentrant {
        DataTypes.SellOrder memory sellOrder = sellOrderList.getSellOrderById(
            id
        );
        require(sellOrder.seller == msg.sender, Errors.CALLER_NOT_SELLER);
        require(sellOrder.isActive == true, Errors.SELL_ORDER_NOT_ACTIVE);
        sellOrderList.deactiveSellOrder(id);
    }

    /**
     * @dev Buy a sell order
     * -  Can be called at anyone
     * @param id The id of sell order
     **/
    function buy(uint256 id) external payable nonReentrant {
        DataTypes.SellOrder memory sellOrder = sellOrderList.getSellOrderById(
            id
        );
        require(sellOrder.seller != msg.sender, Errors.CALLER_IS_SELLER);
        require(sellOrder.isActive == true, Errors.SELL_ORDER_NOT_ACTIVE);
        require(msg.value == sellOrder.price, Errors.VALUE_NOT_EQUAL_PRICE);
        uint256 fee = calculateFee(sellOrder.price);
        sellOrder.seller.transfer(sellOrder.price - fee);
        vault.deposit{value: fee}(fee);
        IERC721(sellOrder.nftAddress).safeTransferFrom(
            sellOrder.seller,
            msg.sender,
            sellOrder.tokenId
        );
        sellOrderList.completeSellOrder(id, msg.sender);
    }

    /**
     * @dev Update price of a sell order
     * - Can only be called by seller
     * @param id The id of sell order
     * @param newPrice The new price of sell order
     **/
    function updatePrice(uint256 id, uint256 newPrice) external nonReentrant {
        DataTypes.SellOrder memory sellOrder = sellOrderList.getSellOrderById(
            id
        );
        require(sellOrder.seller == msg.sender, Errors.CALLER_NOT_SELLER);
        require(sellOrder.isActive == true, Errors.SELL_ORDER_NOT_ACTIVE);
        require(sellOrder.price != newPrice, Errors.PRICE_NOT_CHANGE);

        sellOrderList.updatePrice(id, newPrice);
    }

    /**
     * @dev Get fee
     * - external view function
     * @return feeNumerator and feeDenominator
     **/
    function getFee() external view returns (uint256, uint256) {
        return (feeNumerator, feeDenominator);
    }

    /**
     * @dev Calculate fee
     * - internal view function, called inside buy() function
     * @param price The price of sell order
     * @return feeNumerator and feeDenominator
     **/
    function calculateFee(uint256 price) internal view returns (uint256) {
        uint256 fee = ((price * SAFE_NUMBER * feeNumerator) / feeDenominator) /
            SAFE_NUMBER;
        return fee;
    }
}
