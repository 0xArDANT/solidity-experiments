//SPDX-License-Identifier: MIT
pragma solidity >0.8.14;

contract FundMe {

    uint256 public amount = 1;

    function fund() public payable {
        amount += 1;
        require(msg.value > 1 ether, "Amount too small");
    }
}