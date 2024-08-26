//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MappingExperiment {

    mapping(address => uint256) public soldes;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => mapping (address => mapping(uint256 => bool))) public userPaidAtASpecificDate;

    //Looks like there isn't a limit to nesting mappings
    mapping(address => mapping (address => mapping (address => mapping (uint256 => mapping (address => mapping(uint256 => bool)))))) ultraMap;


    function send(uint256 _amount) public {
        soldes[msg.sender] += _amount;
    }

    function setAllowance(address _allowedAddr, uint256 _amountAllowed) public {
        allowance[msg.sender][_allowedAddr] = _amountAllowed;
    }

    function makePayment (address _allowed, uint256 _date) public {
        userPaidAtASpecificDate[msg.sender][_allowed][_date] = true;
    }
}