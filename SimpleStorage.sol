// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract SimpleStorage {

    string public greeting = "Hello World !";

    // calldata means the argument will not be modified during the function execution
    function setGreeting(string calldata _greeting) public {
        greeting = _greeting;
    }

    // Playing with types
    // bool, uint, int, address, string, bytes

    address public userAdress;
    string public name = "Arold TOUKO";
    uint public age;
    bool public acceptedConditions;

    bytes public surname = "Ardant";
    string public lastName = string(surname);

    function setUserInfos(address _userAdrr, bytes memory _name, uint16 _age, bool _acceptedConditions) public {
        userAdress = _userAdrr;
        name = string(_name);
        age = _age - 1;
        acceptedConditions = _acceptedConditions;
    }

    receive() external payable {}
    
    fallback() external payable {
        name = string(msg.data);
    }


}