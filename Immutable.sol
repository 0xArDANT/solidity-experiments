// SPDX-License-Identifier: MIT
pragma solidity >0.8.14;

contract Immutable {

    uint256 public immutable number = 15;

    constructor(uint256 _num) {
        number = _num;
        number = 123;
        number = 155;
    }

    function updateNumber(uint256 _newNumber) external {
        number = _newNumber;
    }

    /* After some experiments I come to this conclusion:
       The immutable variables can be updated multiple times in the constructor
       But their value can't be updated inside a function.
    */
}