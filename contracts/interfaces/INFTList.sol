// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface INFTList {

  function isAcceptedNFT(address nftAdress) external view returns (bool);

}
