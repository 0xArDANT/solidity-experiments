//SPDX-License-Identifier: MIT
pragma solidity >0.8.9;

import "./DATToken.sol";

contract TestDTAToken {

    DATToken public datToken;

    constructor(address _dtaTokenAddress) {
        datToken = DATToken(_dtaTokenAddress);
    }

    function transferToken (address _to, uint256 _amount) public {
        datToken.transferFrom(msg.sender, _to, _amount);
    }
}