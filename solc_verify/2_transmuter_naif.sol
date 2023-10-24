// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

/// @notice invariant forall (uint i, uint j) !(0 <= i && 0 <= j && i < owns.length && j < owns.length && i != j) || (owns[i] != owns[j])
/// @notice invariant forall (uint i) !(0 <= i && i < owns.length) || exist[owns[i]] && accs[owns[i]].unex >= 0 && accs[owns[i]].exch >= 0
contract Transmuter {
    
    uint256 constant max_v = 2 ** 128 - 1;
    
            
    using SafeIntMath for uint;

    struct Account {uint unex; uint exch;}

    address[] owns;
    mapping(address => Account) accs;
    mapping(address => bool) exist;
    
    uint tb;

    constructor() {
        if (!exist[msg.sender]) {
            exist[msg.sender] = true;
            accs[msg.sender].unex = 0;
            accs[msg.sender].exch = 0;
            owns.push(msg.sender);
        }
        
        tb = 0;
    }

    /// @notice postcondition accs[own].unex == __verifier_old_uint(accs[own].unex) + a
    function deposit(uint a, address own) public {
        accs[own].unex = accs[own].unex.add(a);
    }

    /// @notice postcondition !(__verifier_old_uint(accs[own].unex) < a) || accs[own].unex == __verifier_old_uint(accs[own].unex + a) // OK (false => anything)
    /// @notice postcondition !(__verifier_old_uint(accs[own].unex) >= a) || accs[own].unex == __verifier_old_uint(accs[own].unex) - a
    function withdraw(uint a, address own) public {
        require(a <= max_v && accs[own].unex >= a);
        accs[own].unex = accs[own].unex.sub(a);
    }
    
    /// @notice postcondition !(__verifier_old_uint(accs[own].exch) < a) || accs[own].exch == __verifier_old_uint(accs[own].exch + a) // OK (false => anything)
    /// @notice postcondition !(__verifier_old_uint(accs[own].exch) >= a) || accs[own].exch == __verifier_old_uint(accs[own].exch) - a
    function claim(uint a, address own) public {
        require(a <= max_v && accs[own].exch >= a);
        accs[own].exch = accs[own].exch.sub(a);
    }
    
    /// @notice postcondition !(accs[usr].unex > 0) || s == accs[usr].unex + accs[usr].exch
    /// @notice postcondition !(accs[usr].unex == 0) || s  == 0
    function userStaked(address usr) public view returns (uint s) {
        s = 0;
        if (accs[usr].unex > 0) {
            s = accs[usr].unex.add(accs[usr].exch);
        }
        return s;
    }


    /// @notice postcondition exists (uint i) !(0 <= i && i < owns.length && accs[owns[i]].unex > 0) || t > 0
    /// @notice postcondition forall (uint i) !(0 <= i && i < owns.length && accs[owns[i]].unex > 0) || (accs[owns[i]].unex + accs[owns[i]].exch <= t)
    function totalStaked() public view returns (uint t) {
        t = 0;
    
        uint s_at_i = userStaked(owns[0]);
    
        /// @notice invariant 0 <= i && i <= owns.length
        for (uint i = 0 ; i < owns.length; i++) {
            t = t.add(s_at_i);
            if (i < owns.length - 1){ 
                s_at_i = userStaked(owns[i+1]);
            }
        }
        return t;
    }


    /// @notice postcondition forall (uint i) !(0 <= i && i < owns.length) || (__verifier_old_uint(accs[owns[i]].exch) <= accs[owns[i]].exch)
    /// @notice postcondition forall (uint i) !(0 <= i && i < owns.length) || (__verifier_old_uint(accs[owns[i]].unex) >= accs[owns[i]].unex)
    function exchange(uint a) public {
        tb = tb.add(a);
        uint ts = totalStaked();
        
        if (0 < tb && 0 < ts){
            uint pc = tb.pcent(ts);
            tb = 0;
    
            /// @notice invariant 0 <= i && i <= owns.length
            for (uint i = 0 ; i < owns.length; i++) {
                uint dlt = pc.pcentv(userStaked(owns[i]));
                
                 
                if (accs[owns[i]].unex >= dlt) {
                    accs[owns[i]].unex = accs[owns[i]].unex.sub(dlt);
                    accs[owns[i]].exch = accs[owns[i]].exch.add(dlt);
                }
                else {
                    tb = tb.add(dlt.sub(accs[owns[i]].unex));
                    accs[owns[i]].exch = accs[owns[i]].exch.add(accs[owns[i]].unex);
                    accs[owns[i]].unex = 0;
                }           
            }
        }
    }
    
    // invariants are observations
    function invariants() public view {    
        uint tc = 0;
        
        for (uint i = 0; i < owns.length; i++) {
            address at_i = owns[i];
            tc = tc.add(accs[at_i].exch);
        }
        
        uint t = 0;
        
        for (uint i = 0 ; i < owns.length; i++) {
            address at_i = owns[i];
            uint s_at_i = accs[at_i].unex.add(accs[at_i].exch);        
            t = t.add(s_at_i);
        }
    
        assert(tc <= t);
    
        //uint curr_ts = totalStaked();
        uint curr_ts = 0;
    
        for (uint i = 0 ; i < owns.length; i++) {
            uint s_at_i = userStaked(owns[i]);          
            curr_ts = curr_ts.add(s_at_i);
        }

        assert(curr_ts <= t);
    }
}



library SafeIntMath {
    uint256 constant max_v = 2 ** 128 - 1;
    uint256 constant min_pcent = 1;

    
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
 
