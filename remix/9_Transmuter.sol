// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract Transmuter {

    uint constant def = type(uint).max;

    using Percentage for uint;

    struct Account {uint unex; uint exch; uint tick;}
    struct Tick {uint unex; uint rate;}

    address[] private owns;
    mapping(address => Account) private accs;  
    mapping(address => bool) private exists;
    uint private tb;

    Tick[] private ticks;
    uint private ct;
    
    function initilize() public {
        accs[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = Account(0,0,0);
        exists[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        owns.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        accs[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = Account(0,0,0);
        exists[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = true;
        owns.push(0x617F2E2fD72FD9D5503197092aC168c91465E7f2);
        accs[0x583031D1113aD414F02576BD6afaBfb302140225] = Account(0,0,0);
        exists[0x583031D1113aD414F02576BD6afaBfb302140225] = true;
        owns.push(0x583031D1113aD414F02576BD6afaBfb302140225);
        
        tb = 0;
        
        ticks.push(Tick(0,0));
        ticks.push(Tick(0,0));
        
        ct = 1;
    }
    
    function newlyExch(address own) internal view returns (uint){
        if (ticks[accs[own].tick].unex == 0) {
            return accs[own].unex;
        } 
        else {
            uint rate = ticks[ct].rate - ticks[accs[own].tick].rate;
            return rate.pcentv(accs[own].unex);
        }
    }

    function migrate(address own) public {
        ticks[accs[own].tick].unex -= accs[own].unex;
        accs[own].unex -= newlyExch(own);
        accs[own].exch += newlyExch(own);
        accs[own].tick = ct;
        ticks[ct].unex += accs[own].unex;
    }

    function getUnex(address own) public view returns (uint){
        return accs[own].unex - newlyExch(own);
    }
    
    function getExch(address own) public view returns (uint){
        return accs[own].exch + newlyExch(own);   
    }
    
    
    function deposit(uint a, address own) public {
        require(exists[own]);
        migrate(own);
        accs[own].unex += a;
        ticks[ct].unex += a;
    }
    
    function withdraw(uint a, address own) public {
        require(exists[own]);
        migrate(own);
        require(accs[own].unex >= a);
        accs[own].unex -= a;
        ticks[ct].unex -= a;
    }
    
    function claim(uint a, address own) public {
        require(exists[own]);
        migrate(own);
        require(accs[own].exch >= a);
        accs[own].exch -= a;
    }
    
    function totalUnex() internal view returns (uint) {
        uint s = 0;
        for (uint i = 1 ; i < ticks.length; i++) {
            s += ticks[i].unex;
        }
        return s;
    }
    
    function exchange(uint a) public {
        tb += a;
        uint tu = totalUnex();
        if (tb > 0 && tu > 0) {
            uint pc = tb.pcent(tu);
            tb = 0;
            ct++;
            ticks.push(Tick(0,ticks[ct-1].rate + pc));
            
            for (uint i = 1 ; i < ticks.length; i++) {
                if (ticks[i].unex > 0) {
                    uint rate = ticks[ct].rate - ticks[i].rate;
                    if (rate >= 100) {
                        uint dlt = rate -  100;
                        tb += dlt.pcentv(ticks[i].unex);
                        ticks[i].unex = 0;
                    }
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

