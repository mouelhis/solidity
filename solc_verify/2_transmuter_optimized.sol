// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;
pragma abicoder v2;


contract Transmuter {

    uint256 constant max_v = 2 ** 128 - 1;
            
    using SafeIntMath for uint;

    struct Account {uint unex; uint exch; uint tick;}
    struct Tick {uint unex; uint rate;}

    address[] owns;
    mapping(address => Account) accs;  
    mapping(address => bool) exist;
    uint tb;

    Tick[] ticks;
    uint ct;
    uint tu;
    

    constructor() {
        if (!exist[msg.sender]) {
            exist[msg.sender] = true;
            accs[msg.sender].unex = 0;
            accs[msg.sender].exch = 0;
            owns.push(msg.sender);
        }

        
        ticks.push(Tick(0,0));
        ticks.push(Tick(0,0));
        
        tb = 0;
        ct = 1;
        tu = 0;

        
    }

    function migrate(address own) public {
        ticks[accs[own].tick].unex = ticks[accs[own].tick].unex.sub(accs[own].unex);

        uint ne = newlyExchanged(own);
        
        accs[own].unex = accs[own].unex.sub(ne);
        accs[own].exch = accs[own].exch.add(ne);
        accs[own].tick = ct; 
        ticks[ct].unex = ticks[ct].unex.add(accs[own].unex);
    }

    function newlyExchanged(address own) view public returns (uint){
        if (ticks[accs[own].tick].unex == 0) {
            return accs[own].unex;
        }
        else {
            uint rate = ticks[ct].rate.sub(ticks[accs[own].tick].rate);
            return accs[own].unex * rate;
        }
    }

    function getUnexchangedBalance(address own) view public returns (uint){
        uint ne = newlyExchanged(own);
        return accs[own].unex.sub(ne);
    }
    
    function getExchangedBalance(address own) view public returns (uint){
        uint ne = newlyExchanged(own);
        return accs[own].exch.add(ne);
    }

    function deposit(uint a, address own) public {
        migrate(own);
        accs[own].unex = accs[own].unex.add(a);
        ticks[ct].unex = ticks[ct].unex.add(a);
    }

    function withdraw(uint a, address own) public {
        migrate(own);
        accs[own].unex = accs[own].unex.sub(a);
        ticks[ct].unex = ticks[ct].unex.sub(a);
    }

    function claim(uint a, address own) public {
        migrate(own);
        accs[own].exch = accs[own].exch.sub(a);
    }

    function exchange(uint a) public {
        tb = tb.add(a);

        if (0 < tb && 0 < tu){        
            uint pc = tb.pcent(tu);
            tb = 0;
            
            ct = ct.add(1);
            ticks.push(Tick(0,ticks[ct-1].rate.add(pc)));
            //ticks[ct].rate = ticks[ct-1].rate + pc;
            
            for (uint i = 1 ; i <= ticks.length; i++) {
                if (ticks[i].unex > 0) {
                    uint rate = ticks[ct].rate.sub(ticks[i].rate);
                    if (rate >= 1) {
                        tb = tb.add(ticks[i].unex.mul(rate.sub(1)));
                        ticks[i].unex = 0;
                        tu = tu.sub(ticks[i].unex);
                    }
                }
            }
        }
    }    
    
}



library SafeIntMath {
    uint256 constant max_v = 2 ** 128 - 1;
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); //Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function pcent(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a <= max_v && b <= max_v);
        //require(a <= b);
        uint256 at100 = a * 100;
        require(a == 0 || at100 / a == 100);
        uint256 p = (at100 + b / 2) / b;
        if (p == 0) {
            p = 1;
        }
        return p;  
    }

    function pcentv(uint256 p, uint256 b) internal pure returns (uint256) {
        uint256 v = p * b;
        require(p == 0 || v / p == b);
        return (v / 100);
    }
}
