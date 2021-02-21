// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

/**
 * @title Vault contract
 * @dev The vault of Market
 * - Keep transaction fees of Market
 * - Owned by the Sun* Blockchain
 * @author Sun* Blockchain
 **/

contract Vault is Initializable {
    using SafeMath for uint256;
    IAddressesProvider public addressesProvider;

    uint256 public fund;

    event Withdraw(address indexed receiver, uint256 amount);
    event Deposit(address indexed sender, uint256 amount);

    modifier onlyMarketAdmin() {
        require(
            addressesProvider.getAdmin() == msg.sender,
            Errors.CALLER_NOT_MARKET_ADMIN
        );
        _;
    }

    modifier onlyMarket() {
        require(
            addressesProvider.getMarket() == msg.sender,
            Errors.CALLER_NOT_MARKET
        );
        _;
    }

    /**
     * @dev Function is invoked by the proxy contract when the Vault contract is added to the
     * AddressesProvider of the market.
     * - Caching the address of the AddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the AddressesProvider
     **/
    function initialize(address provider) public initializer {
        addressesProvider = IAddressesProvider(provider);
    }

    /**
     * @dev Deposit fee when user buyNFT
     * - Can only be called by Market
     * @param amount The amount of money deposit
     */
    function deposit(uint256 amount) public payable onlyMarket {
        require(amount == msg.value, Errors.NOT_ENOUGH_MONEY);
        fund = fund.add(amount);
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Withdraw balance from contract
     * - Can only be called by admin
     * @param amount The amount of money withdrawn
     * @param receiver The recipent when withdrawing
     */
    function withdraw(uint256 amount, address payable receiver)
        external
        onlyMarketAdmin
    {
        require(amount <= fund, Errors.INSUFFICIENT_BALANCE);
        receiver.transfer(amount);
        fund = fund.sub(amount);
        emit Withdraw(receiver, amount);
    }
}
