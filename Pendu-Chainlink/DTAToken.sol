// SPDX-License-Identifier: MIT
pragma solidity >0.8.9;

contract DTAToken {

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    
    mapping (address => uint256) public balanceOf;
    mapping (address allower => mapping(address spender => uint256 amount)) public allowance;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        name = "DTA Token";
        symbol = "DTA";
        decimals = 18;

        owner = msg.sender;
    }

    function mint(uint256 _newSupply) public onlyOwner {
        totalSupply += _newSupply;
        balanceOf[owner] += _newSupply;
    }

    function transfer(address _to, uint256 _amount) public {
        require(_amount <= balanceOf[msg.sender], "Not enough funds");
        require(_to != address(0), "You can't send funds to the null address");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
    }

    function approve(address _spender, uint256 _amount) public {
        allowance[msg.sender][_spender] = _amount;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public {
        require(balanceOf[_from] >= _amount, "Not enough funds");

        if(msg.sender != _from) {
            require(allowance[_from][msg.sender] >= _amount, "Not enough allowance");
            allowance[_from][msg.sender] -= _amount;

        }

        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
    }




}