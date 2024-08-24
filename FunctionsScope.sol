// SPDX-License-Identifier: MIT
pragma solidity >0.8.14;

interface IFunctionScope {
    function newNumber(uint256) external;
    function updateNumber(uint256) external;
}


contract FunctionScope is IFunctionScope {

    uint256 public number;

    function setNumber(uint256 _number) private {
        number = _number;
    }

    function newNumber(uint256 _newNumber) external {
        setNumber(_newNumber);
    }

    function defineNumber(uint256 _number) internal {
        updateNumber(_number);
    }

    function updateNumber(uint256 _number) public {
        number = _number;
    }
}

contract ReaderContract {

    IFunctionScope test;

    // specify the implementation of the function scope I want to interact with
    constructor(address _functionScopeContractAddress) {
        test = IFunctionScope(_functionScopeContractAddress);
    }

    function setNumber(uint256 _number) public {
        test.newNumber(_number);
    }
}