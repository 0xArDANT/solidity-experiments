// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import {SimpleStorage, SimpleStorage2} from "./SimpleStorage.sol";
import {SimpleStorage} from "./SimpleStorage.sol";

contract StorageFactory {
    
    SimpleStorage[] public listOfSimpleStorages;

    function createSimpleStorage() public {
        SimpleStorage simpleStorage = new SimpleStorage();
        listOfSimpleStorages.push(simpleStorage);
    }
    
    // Function to store a number
    function sfStore(uint256 _simpleStorageIndex, uint256 _number) public {
        listOfSimpleStorages[_simpleStorageIndex].store(_number);
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns (uint256) {
        return listOfSimpleStorages[_simpleStorageIndex].retrieve();
    }
}