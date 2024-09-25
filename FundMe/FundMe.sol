//SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import {PriceConverter} from "./PriceConverter.sol";

// This contract works only for tokens with 18 decimals

contract FundMe {
    using PriceConverter for uint256;

    address private priceFeedAddress;
    address private immutable owner;
    uint256 public minAmountToFundInUSD;

    mapping(address => uint256) public fundingsInUSD;

    error NotOwner();
    error AmountTooSmall();

    modifier onlyOwner() {
        require(msg.sender == owner, NotOwner());
        _;
    }

    constructor(address _priceFeedAddress, uint256 _minimumFunding) {
        owner = msg.sender;
        minAmountToFundInUSD = _minimumFunding * 1e18;
        priceFeedAddress = _priceFeedAddress;
    }

    //The funding amount should be at least 50 dollars

    function fund() external payable {
        require(msg.value > 0, AmountTooSmall());
        uint256 amountToFund = msg.value.getConversionRate(priceFeedAddress);
        require(amountToFund >= minAmountToFundInUSD, AmountTooSmall());
        fundingsInUSD[msg.sender] += amountToFund;
    }

    function changePriceFeedContractAddress(address _addr) public onlyOwner {
        priceFeedAddress = _addr;
    }

    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
