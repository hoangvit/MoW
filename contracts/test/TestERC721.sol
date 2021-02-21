// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract TestERC721 is ERC721, Ownable {

  constructor(string memory name_, string memory symbol_) public  ERC721(name_, symbol_) {
  }

  function mintUniqueTokenTo(address _to, uint256 _tokenId) public onlyOwner {
    _safeMint(_to, _tokenId);
  }
}
