// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/DiamondTokenFacet.sol";
import "../contracts/facets/NameFacet.sol";
import "../contracts/Diamond.sol";

import "forge-std/Test.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    DiamondTokenFacet tokenF;

    // NameFacet used for upgrade.
    NameFacet nameF;

    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        tokenF = new DiamondTokenFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(tokenF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondTokenFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
        
        //Initialize the token
        DiamondTokenFacet(address(diamond)).initializer();
    }

    function testDiamondToken() public {
        string memory name = DiamondTokenFacet(address(diamond)).name();
        string memory symbol = DiamondTokenFacet(address(diamond)).symbol();
        uint256 totalSupply = DiamondTokenFacet(address(diamond)).totalSupply();

        assertEq(name, "Diamond Token");
        assertEq(symbol, "DTKN");
        assertEq(totalSupply, 1_000_000e18);
    }

    // multiple initialization should fail
    function testFailMultipleInitialize() public {
        DiamondTokenFacet(address(diamond)).initializer();
    }

    // upgrade test with new `NameFacet`
    function testNameFacetUpgrade() public {
        address _diamond = address(diamond);
        nameF = new NameFacet();

        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = (
            FacetCut({
                facetAddress: address(nameF),
                action: FacetCutAction.Replace,
                functionSelectors: generateSelectors("NameFacet")
            })
        );
        // replace function selectors
        IDiamondCut(_diamond).diamondCut(cut, address(0), "");
        string memory name = NameFacet(_diamond).name();
        string memory symbol = NameFacet(_diamond).symbol();

        assertEq(name, "Diamond Token V2");
        assertEq(symbol, "DTKN V2");
    }

    function generateSelectors(string memory _facetName)
        internal
        returns (bytes4[] memory selectors)
    {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
