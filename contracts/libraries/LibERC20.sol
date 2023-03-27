// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TokenStorage} from "./LibAppStorage.sol";

library LibERC20 {

    error InvalidAddress();
    error InsufficientBalance();

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(TokenStorage storage ts, address _from, address _to, uint256 _value) internal {
        if(_from == address(0)) revert InvalidAddress();
        if(_to == address(0)) revert InvalidAddress();
        if(ts.balances[_from] < _value) revert InsufficientBalance();

        unchecked {
            ts.balances[_from] -= _value;
            ts.balances[_to] += _value;
        }

        emit Transfer(_from, _to, _value);
    }

    function approve(TokenStorage storage ts, address _owner, address _spender, uint256 _value) internal {
        if(_owner == address(0)) revert InvalidAddress();
        if(_spender == address(0)) revert InvalidAddress();

        ts.allowances[_owner][_spender] += _value;

        emit Approval(_owner, _spender, _value);
    }

}