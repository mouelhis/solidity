// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

contract Token {
    using SafeMath for uint;
    
    uint constant max_to_size = 10;
    uint constant max_to_balance = 10000;

    mapping(address => uint) balances;
   
    /// @notice precondition forall (uint i) !(0 <= i && i < max_to_size) || (from != to[i])
    /// @notice precondition forall (uint i, uint j) !(0 <= i && 0 <= j && i < max_to_size && j < max_to_size && i != j) || (to[i] != to[j])
    /// @notice precondition balances[from] >= (val * max_to_size)
    /// @notice precondition forall (uint i) !(0 <= i && i < max_to_size) || (0 <= balances[to[i]] && balances[to[i]] <= max_to_balance)
    /// @notice postcondition balances[from]  == __verifier_old_uint(balances[from]) - (val * to.length)
    /// @notice postcondition balances[from] >= 0
    /// @notice postcondition forall (uint i) !(0 <= i && i < max_to_size) || (balances[to[i]] == __verifier_old_uint(balances[to[i]]) + val)
    /// @notice postcondition forall (uint i) !(0 <= i && i < max_to_size) || (balances[to[i]] >= 0)
    function payAll(address from, address[max_to_size] memory to, uint val)  public {
        uint amount = val.mul(to.length);
        
        if (balances[from] >= amount){
            balances[from] = balances[from].sub(amount);
            
            /// @notice invariant 0 <= i && i <= max_to_size
            for (uint i = 0; i < max_to_size; i++) {
                balances[to[i]] = balances[to[i]].add(val);               
            }
        }
        else{
            revert();
        }
        
    }

    uint constant max_val = 50000;

    /// @notice precondition from != to
    /// @notice precondition val <= balances[from]
    /// @notice precondition 0 <= balances[to] 
    /// @notice postcondition balances[from]  == __verifier_old_uint(balances[from]) - val
    /// @notice postcondition balances[from] >= 0
    /// @notice postcondition balances[to]  == __verifier_old_uint(balances[to]) + val
    /// @notice postcondition balances[to] >= 0
    function transfer(address from, address to, uint val) public {
        uint updatedFrom;
        uint updatedTo;
        if (balances[from] >= val) {
            updatedFrom = balances[from].sub(val);
            updatedTo = balances[to].add(val);
        } else {
            revert();
        }
        balances[from] = updatedFrom;
        balances[to] = updatedTo;
    }
}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
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
}
