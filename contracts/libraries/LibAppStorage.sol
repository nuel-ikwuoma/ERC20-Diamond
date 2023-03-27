// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TokenStorage {
    uint256 initialized;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
}

library LibAppStorage {
    function tokenStorage() internal pure returns(TokenStorage storage ts) {
        assembly {
            ts.slot := 0
        }
    }
}