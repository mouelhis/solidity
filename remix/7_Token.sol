// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
contract Token {
    
    mapping(address=>uint) balances;

    function initilize() public {
        balances[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = 50;
        balances[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = 0;
        balances[0x583031D1113aD414F02576BD6afaBfb302140225] = 0;
    }

    function payAll(address from, address[] memory to, uint val)  payable public {
        require(to.length == 4); 
        uint amount = val * to.length;
        require(balances[from] >= amount);   
        balances[from] -= amount;
        for (uint i = 0; i < to.length; i++) {
            balances[to[i]] += val;
        }
    }
}
