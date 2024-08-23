// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.14;

contract Time {

    uint public lastCall;

    function makeCalls () public returns(uint256){
        require (block.timestamp > lastCall + 1 minutes, "You should wait the one-day rule to be completed before another call");
        lastCall = block.timestamp;
        return lastCall;
    }

    mapping (address => uint256) userLastCalls;

    function faucet() public payable {
        require(block.timestamp > userLastCalls[msg.sender] + 1 days, "Please wait until the end of the freezing period");
        require(address(this).balance >= 1 ether, "The contract doesn't have enough funds");
        payable(msg.sender).transfer(1 ether);
        userLastCalls[msg.sender] = block.timestamp;
    }

    receive() external payable {}

}