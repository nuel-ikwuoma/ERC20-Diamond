// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TokenStorage} from "../libraries/LibAppStorage.sol";
import {LibERC20} from "../libraries/LibERC20.sol";

import "../interfaces/IERC20.sol";

error InsufficientAllowance();
error AlreadyInitialized();
contract DiamondTokenFacet is IERC20 {
    TokenStorage s;

    /// @notice initializes the token contract.
    /// @dev this procedure should only be called once.
    function initializer() external {
        if(s.initialized == 1) revert AlreadyInitialized();
        s.totalSupply = 1_000_000e18;
        s.initialized = 1;
    }

    /// @notice returns the name of the token.
    function name() external pure override returns(string memory) {
        return "Diamond Token";
    }

    /// @notice returns the symbol of the token.
    function symbol() external pure override returns(string memory) {
        return "DTKN";
    }

    /// @notice returns the token decimals.
    function decimals() external pure override returns(uint8) {
        return 18;
    }

    /// @notice returns the token total supply.
    function totalSupply() external view override returns(uint256) {
        return s.totalSupply;
    }

    /// @notice returns the balance of an address.
    function balanceOf(address _owner) external view override returns (uint256 balance) {
        balance = s.balances[_owner];
    }

    /// @notice transfers `_value` token from `caller` to `_to`.
    function transfer(address _to, uint256 _value) external override returns (bool success) {
        LibERC20.transfer(s, msg.sender, _to, _value);
        success = true;
    }

    /// @notice transfers `_value` tokens, from `_from` to `_to`.
    /// @dev   `caller` must be initially approved.
    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success) {

        uint256 _allowance = s.allowances[_from][msg.sender];
        if(_allowance < _value) revert InsufficientAllowance();
        
        LibERC20.transfer(s, _from, _to, _value);
        unchecked {
            s.allowances[_from][msg.sender] -= _value;
        }

        success = true;
    }

    /// @notice approves `_spender` for `_value` tokens, owned by caller.
    function approve(address _spender, uint256 _value) external override returns (bool success) {
        LibERC20.approve(s, msg.sender, _spender, _value);
        success = true;
    }

    /// @notice gets the allowance for spender `_spender` by the owner `_owner`
    function allowance(address _owner, address _spender) external override view returns (uint256 remaining) {
        remaining = s.allowances[_owner][_spender];
    }
}