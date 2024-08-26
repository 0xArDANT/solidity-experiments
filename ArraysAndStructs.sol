//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Liste {

    struct Animal {
        string name;
        string race;
        uint256 age;
    }

    Animal[] public animals;

    Animal public dog = Animal("Rocky", "Dog", 15);
    Animal public cat = Animal("Minou", "Cat", 5);
    Animal public lion = Animal ("Exod", "Lion", 10);

    constructor () {
        animals.push(dog);
        animals.push(cat);
        animals.push(lion);
    }

    function addAnimal(string calldata _name, string calldata _race, uint256 _age) public {
        animals.push(Animal(_name, _race, _age));
    }
}