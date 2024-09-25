//SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// This contract works only for tokens with 18 decimals

contract FundMe {
    AggregatorV3Interface internal dataFeed;
    address internal immutable owner;
    uint256 public minAmountToFundInUSD;

    mapping(address => uint256) public fundingsInUSD;

    error NotOwner();
    error AmountTooSmall();

    modifier onlyOwner() {
        require(msg.sender == owner, NotOwner());
        _;
    }

    constructor(address priceFeedContractAddress, uint256 _minimumFunding) {
        owner = msg.sender;
        dataFeed = AggregatorV3Interface(priceFeedContractAddress);
        minAmountToFundInUSD = _minimumFunding * 1e18;
    }

    function changePriceFeedContractAddress(address addr) public onlyOwner {
        dataFeed = AggregatorV3Interface(addr);
        dataFeed.description();
    }

    //The funding amount should be at least 50 dollars

    function fund() public payable {
        require(msg.value > 0, AmountTooSmall());
        uint256 amountToFund = getConversionRate(msg.value);
        require(amountToFund >= minAmountToFundInUSD, AmountTooSmall());
        fundingsInUSD[msg.sender] += amountToFund;
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = dataFeed.latestRoundData();
        return uint256(price) * 1e10;
    }

    function getConversionRate(uint256 amountInEther)
        public
        view
        returns (uint256)
    {
        uint256 priceInWei = getPrice();
        uint256 usdPrice = (priceInWei * amountInEther) / 1 ether;
        return usdPrice;
    }

    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
