// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;


/**
 * @title AddressesProvider contract
 * @dev Main registry of addresses part of or connected to the NFT Market, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Sun* Blockchain
 * @author Sun* Blockchain
 **/

interface IAddressesProvider {

  function setAddress(bytes32 id, address newAddress, bytes memory params) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getNFTList() external view returns (address);

  function setNFTListImpl(address ercList, bytes memory params) external;

  function getMarket() external view returns (address);

  function setMarketImpl(address market, bytes memory params) external;

  function getSellOrderList() external view returns (address);

  function setSellOrderListImpl(address sellOrderList, bytes memory params) external;

  function getVault() external view returns (address);

  function setVaultImpl(address vault, bytes memory params) external;

  function getAdmin() external view returns (address);

  function setAdmin(address admin) external;
}
