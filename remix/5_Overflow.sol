// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

contract Token {

    uint value = 1;
    
    function overflow() public {
        if (value == 1){
            value = uint(-1);
        }
    }
}
