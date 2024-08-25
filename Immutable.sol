// SPDX-License-Identifier: MIT
pragma solidity >0.8.14;

contract Immutable {

    uint256 public immutable number = 15;

    constructor(uint256 _num) {
        number = _num;
        number = 123;
    }

    // After some experiments I come to this conclusion:
    // The only point I see for using immutable is saving gas by having the value saved directly in the bytecode instead of blockchain storage
    // It has meaning only if we won't change the value later(it is possible). For example a wrapper contract address, a ERC-20 token address.

}