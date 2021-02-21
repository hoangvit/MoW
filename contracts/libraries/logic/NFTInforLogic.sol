// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {DataTypes} from '../types/DataTypes.sol';

library NFTInforLogic {

  /**
   * @dev Registers a nft
   * @param nftInfor The nftInfor object
   **/
  function register(DataTypes.NFTInfor storage nftInfor) internal {
    nftInfor.isRegistered = true;
    nftInfor.isAccepted = false;
  }

  /**
   * @dev Accepts a nft
   * @param nftInfor The nftInfor object
   **/
  function accept(DataTypes.NFTInfor storage nftInfor) internal {
    nftInfor.isAccepted = true;
  }

}
