//SPDX-License-Identifier: MIT
pragma solidity >0.8.20;

contract FundMe {

    uint256 public amount = 1;

    function fund() public payable returns(uint256) {
        amount += 1;
        require(msg.value > 1 ether, "Amount too small");
        return block.chainid;

    }
}