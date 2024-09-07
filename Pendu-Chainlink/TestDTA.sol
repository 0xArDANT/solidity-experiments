//SPDX-License-Identifier: MIT
pragma solidity >0.8.9;

import "./DTAToken.sol";

contract TestDTAToken {

    DTAToken public dtaToken;

    constructor(address _dtaTokenAddress) {
        dtaToken = DTAToken(_dtaTokenAddress);
    }

    function transferToken (address _to, uint256 _amount) public {
        dtaToken.transferFrom(msg.sender, _to, _amount);
    }
}