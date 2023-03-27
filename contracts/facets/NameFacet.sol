// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NameFacet {
    function name() external pure returns(string memory) {
        return "Diamond Token V2";
    }

    function symbol() external pure returns(string memory) {
        return "DTKN V2";
    }
}