// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(address _priceFeedAddress)
        internal
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 1e10;
    }

    function getConversionRate(uint256 amountInEther, address _priceFeedAddress)
        internal
        view
        returns (uint256)
    {
        uint256 priceInWei = getPrice(_priceFeedAddress);
        uint256 usdPrice = (priceInWei * amountInEther) / 1 ether;
        return usdPrice;
    }
}
