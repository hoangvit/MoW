// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library Errors {
    // common errors
    string
        public constant CALLER_NOT_MARKET_ADMIN = "Caller is not the market admin"; // 'The caller must be the market admin'
    string public constant CALLER_NOT_MARKET = "Caller is not the market"; // 'The caller must be Market'
    string public constant CALLER_NOT_NFT_OWNER = "Caller is not nft owner"; // 'The caller must be the owner of nft'
    string public constant CALLER_NOT_SELLER = "Caller is not seller"; // 'The caller must be the seller'
    string public constant CALLER_IS_SELLER = "Caller is seller"; // 'The caller must be not the seller'

    string public constant NFT_NOT_CONTRACT = "NFT address is not contract"; // 'The address must be contract address'
    string public constant NFT_ALREADY_REGISTERED = "NFT already registered"; // 'The nft already registered'
    string public constant NFT_NOT_REGISTERED = "NFT is not registered"; // 'The nft not registered'
    string public constant NFT_ALREADY_ACCEPTED = "NFT already accepted"; // 'The nft not registered'
    string public constant NFT_NOT_ACCEPTED = "NFT is not accepted"; // 'The nft address muse be accepted'
    string
        public constant NFT_NOT_APPROVED_FOR_MARKET = "NFT is not approved for Market"; // 'The nft must be approved for Market'

    string public constant SELL_ORDER_NOT_ACTIVE = "Sell order is not active"; // 'The sell order must be active'
    string public constant SELL_ORDER_DUPLICATE = "Sell order is duplicate"; // 'The sell order must be unique'

    string public constant NOT_ENOUGH_MONEY = "Send not enough token"; // 'The msg.value must be equal amount'
    string public constant VALUE_NOT_EQUAL_PRICE = "Msg.value not equal price"; // 'The msg.value must equal price'
    string
        public constant DEMONINATOR_NOT_GREATER_THAN_NUMERATOR = "Demoninator not greater than numerator"; // 'The fee denominator must be greater than fee numerator'

    string public constant RANGE_IS_INVALID = "Range is invalid"; // 'The range must be valid'

    string public constant PRICE_NOT_CHANGE = "Price is not change"; // 'The new price must be not equal price'
    string public constant INSUFFICIENT_BALANCE = "Insufficient balance"; // 'The fund must be equal or greater than amount to withdraw'
}
