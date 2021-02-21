// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {NFTInforLogic} from "../libraries/logic/NFTInforLogic.sol";

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

/**
 * @title NFTList contract
 * @dev The registrar addresses the NFTs so they can be traded on the Market
 * - Acting as a place to register, the contract owner registers and the admin accepts
 * - Owned by the Sun* Blockchain
 * @author Sun* Blockchain
 **/
contract NFTList is Initializable {
    using SafeMath for uint256;
    using NFTInforLogic for DataTypes.NFTInfor;

    IAddressesProvider public addressesProvider;

    mapping(address => DataTypes.NFTInfor) internal _nfts;
    mapping(uint256 => address) internal _nftsList;
    uint256 internal _nftsCount;
    address[] internal _acceptedList;

    event Initialized(address indexed provider);
    event NFTRegistered(address indexed nftAddress, uint256 id);
    event NFTAccepted(address indexed nftAddress);

    modifier onlyMarketAdmin() {
        require(
            addressesProvider.getAdmin() == msg.sender,
            Errors.CALLER_NOT_MARKET_ADMIN
        );
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the NFTList contract is added to the
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
     * @dev Register a nft
     * - Can be called by anyone
     * @param nftAddress The address of the nft contract
     **/
    function registerNFT(address nftAddress) external {
        require(Address.isContract(nftAddress), Errors.NFT_NOT_CONTRACT);
        require(!_nfts[nftAddress].isRegistered, Errors.NFT_ALREADY_REGISTERED);
        _nfts[nftAddress].register();
        _addNFTToList(nftAddress);
        emit NFTRegistered(nftAddress, _nftsCount);
    }

    /**
     * @dev Accept a nft
     * - Can only be called by admin
     * @param nftAddress The address of the nft contract
     **/
    function acceptNFT(address nftAddress) external onlyMarketAdmin {
        require(_nfts[nftAddress].isRegistered, Errors.NFT_NOT_REGISTERED);
        require(!_nfts[nftAddress].isAccepted, Errors.NFT_ALREADY_ACCEPTED);
        _nfts[nftAddress].accept();
        _addNFTToAcceptedList(nftAddress);
        emit NFTAccepted(nftAddress);
    }

    /**
     * @dev Get the information of nft
     * @param nftAddress The address of the nft
     **/
    function getNFTInfor(address nftAddress)
        public
        view
        returns (DataTypes.NFTInfor memory)
    {
        return _nfts[nftAddress];
    }

    /**
     * @dev Get the amount of all registered nft
     **/
    function getNFTsCount() public view returns (uint256) {
        return _nftsCount;
    }

    /**
     * @dev Get address of all accepted nft
     **/
    function getAcceptedNFTs() public view returns (address[] memory) {
        return _acceptedList;
    }

    /**
     * @dev check nft has been accepted or not
     * @param nftAddress The address of nft
     * @return true of fasle
     */
    function isAcceptedNFT(address nftAddress) public view returns (bool) {
        return _nfts[nftAddress].isAccepted;
    }

    /**
     * @dev add nft to _nftList
     * internal function called by inside registerNFT() function
     * @param nftAddress The address of nft
     */
    function _addNFTToList(address nftAddress) internal {
        _nftsCount = _nftsCount.add(1);
        _nfts[nftAddress].id = _nftsCount;
        _nftsList[_nftsCount] = nftAddress;
    }

    /**
     * @dev add nft to _acceptedList
     * internal function called by inside acceptNFT() function
     * @param nftAddress The address of nft
     */
    function _addNFTToAcceptedList(address nftAddress) internal {
        _acceptedList.push(nftAddress);
    }
}
