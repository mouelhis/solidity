// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Transmuter {
    

    using Percentage for uint;

    struct Account {uint unex; uint exch;}

    address[] private owns;
    mapping(address => Account) private accs;
    mapping(address => bool) private exists;
    uint private tb;

    function initilize() public {
        accs[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = Account(0,0);
        exists[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        owns.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        accs[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = Account(0,0);
        exists[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = true;
        owns.push(0x617F2E2fD72FD9D5503197092aC168c91465E7f2);
        accs[0x583031D1113aD414F02576BD6afaBfb302140225] = Account(0,0);
        exists[0x583031D1113aD414F02576BD6afaBfb302140225] = true;
        owns.push(0x583031D1113aD414F02576BD6afaBfb302140225);
        tb = 0;
    }
    

    function getUnex(address own) public view returns (uint) {
        return accs[own].unex;
    }
    
    function getExch(address own) public view returns (uint) {
        return accs[own].exch;
    }

    function deposit(uint a, address own) public {
        require(exists[own]);
        accs[own].unex += a;
    }

    function withdraw(uint a, address own) public {
        require(exists[own] && accs[own].unex >= a);
        accs[own].unex -= a;
    }

    function claim(uint a, address own) public {
        require(exists[own] && accs[own].exch >= a);
        accs[own].exch -= a;
    }
    
    function userStaked(address usr) public view returns (uint) {
        if (accs[usr].unex == 0) {
            return 0;
        }
        else {
            return accs[usr].unex + accs[usr].exch;
        }
    }


    function totalStaked() public view returns (uint) {
        uint s = 0;
    
        for (uint i = 0 ; i < owns.length; i++) {
            s += userStaked(owns[i]);
        }
        return s;
    }


    function exchange(uint a) public {
        tb += a;
        uint ts = totalStaked();
        
        if (0 < tb && 0 < ts){
            uint pc = tb.pcent(ts);
            tb = 0;
    
            for (uint i = 0 ; i < owns.length; i++) {
                uint dlt = pc.pcentv(userStaked(owns[i]));
                
                 
                if (accs[owns[i]].unex >= dlt) {
                    accs[owns[i]].unex -= dlt;
                    accs[owns[i]].exch += dlt;
                }
                else {
                    tb += dlt - accs[owns[i]].unex;
                    accs[owns[i]].exch += accs[owns[i]].exch;
                    accs[owns[i]].unex = 0;
                }           
            }
        }
    }
}



library Percentage {
    uint256 constant min_pcent = 1;

    function pcent(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 at100 = a * 100;
        require(a == 0 || at100 / a == 100);
        uint256 p = (at100 + b / 2) / b;
        if (p == 0 && a > 0 && b > 0) {
            p = min_pcent;
        }
        return p;  
    }

    function pcentv(uint256 p, uint256 b) internal pure returns (uint256) {
        uint256 v = p * b;
        require(p == 0 || v / p == b);
        return (v / 100);
    }
}
 
