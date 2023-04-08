// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibERC20.sol";
import "../facets/DiamondTokenFacet.sol";

import "solady/utils/ECDSA.sol";

error DeadlineExceeded();
error InvalidSigner();

contract PermitFacet {
    TokenStorage ts;

    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
    bytes32 internal constant TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 constant HASHED_VERSION = keccak256(abi.encode(bytes("1")));

    uint256 immutable CACHE_CHAINID = block.chainid;
    bytes32 immutable HASHED_NAME;
    bytes32 immutable DOMAIN_SEPARATOR;

    constructor(address _diamondAddress) {
        // call Diamond to get name.
        DiamondTokenFacet diamond = DiamondTokenFacet(_diamondAddress);
        HASHED_NAME = keccak256(bytes(diamond.name()));
        DOMAIN_SEPARATOR = buildDomainSeperator();
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        if(block.timestamp > deadline) revert DeadlineExceeded();
        bytes32 _structHash;
        bytes32 _permitHash = PERMIT_TYPEHASH;
        uint256 nonce = ts.nonces[owner]++;
        assembly {
            // load free memory pointer (fmp)
            let fmp := mload(0x40)
            mstore(fmp, _permitHash)
            mstore(add(fmp, 0x20), owner)
            mstore(add(fmp, 0x40), spender)
            mstore(add(fmp, 0x60), value)
            mstore(add(fmp, 0x80), nonce)
            mstore(add(fmp, 0xa0), deadline)
            _structHash := keccak256(fmp, 0xc0)
        }

        bytes32 _domainSeperator = domainSeperatorV4();
        bytes32 _hashDigest;

        assembly {
            mstore(0x0, "\x19\x01")                         // ethereum sig header
            mstore(0x2, _domainSeperator)                   // domain hash
            mstore(0x22, _structHash)                       // stuct hash
            _hashDigest := keccak256(0, 0x42)
            mstore(0x22, 0)                                 // clean fmp that was over written
        }
        address signer = ECDSA.recover(_hashDigest, v, r, s);
        if(signer != owner) revert InvalidSigner();
        LibERC20.approve(ts, owner, spender, value);
    }

    function nonces(address owner) external view returns (uint256) {
        return ts.nonces[owner];
    }

    function domainSeparator() external view returns (bytes32) {
        return domainSeperatorV4();
    }

    function domainSeperatorV4() internal view returns(bytes32) {
        if(block.chainid == CACHE_CHAINID) {
            return DOMAIN_SEPARATOR;
        }
        return buildDomainSeperator();
    }

    function buildDomainSeperator() private view returns(bytes32 domainSeparator_) {
        bytes32 _hashName = HASHED_NAME;
        bytes32 _hashedVersion = HASHED_VERSION;

        assembly {
            let fmp := mload(0x40)
            mstore(fmp, TYPE_HASH)
            mstore(add(fmp, 0x20), _hashName)
            mstore(add(fmp, 0x40), _hashedVersion)
            mstore(add(fmp, 0x60), chainid())
            mstore(add(fmp, 0x80), address())
            domainSeparator_ := keccak256(fmp, 0xa0)
        }
    }
}