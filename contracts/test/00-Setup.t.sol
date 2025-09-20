// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/AccessControl.sol";
import "../src/Holders.sol";
import "../src/Designers.sol";
import "../src/Appraisals.sol";
import "../src/ReactionPacks.sol";
import "../src/TestERC20.sol";
import "../src/TestERC721.sol";
import "../src/Library.sol";

contract SetupTest is Test {
    AccessControl public accessControl;
    Holders public holders;
    Designers public designers;
    Appraisals public appraisals;
    ReactionPacks public reactionPacks;
    TestERC20 public monaToken;
    TestERC721 public podeToken;

    address public admin = address(0x1);
    address public holder1 = address(0x2);
    address public holder2 = address(0x3);
    address public designer1 = address(0x4);
    address public user1 = address(0x5);
    address public user2 = address(0x6);

    uint256 public constant BASE_PRICE = 100 * 10**18; // 100 MONA
    uint256 public constant PRICE_INCREMENT = 10 * 10**18; // 10 MONA

    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy tokens
        monaToken = new TestERC20();
        podeToken = new TestERC721();
        
        // Deploy core contracts
        accessControl = new AccessControl(address(monaToken));
        holders = new Holders(address(accessControl));
        designers = new Designers(address(accessControl), address(holders));
        appraisals = new Appraisals(address(accessControl), address(holders));
        reactionPacks = new ReactionPacks(
            address(accessControl),
            address(designers),
            address(monaToken),
            BASE_PRICE,
            PRICE_INCREMENT
        );
        
        // Set contract references
        accessControl.setPodeToken(address(podeToken));
        holders.setAppraisals(address(appraisals));
        holders.setDesigners(address(designers));
        holders.setReactionPacks(address(reactionPacks));
        appraisals.setReactionPacks(address(reactionPacks));
        
        // Mint tokens for testing
        podeToken.mint(holder1, 1);
        podeToken.mint(holder2, 1);
        
        monaToken.mint(holder1, 10000 * 10**18);
        monaToken.mint(holder2, 10000 * 10**18);
        monaToken.mint(user1, 10000 * 10**18);
        monaToken.mint(user2, 10000 * 10**18);
        
        vm.stopPrank();
    }

    function testDeploymentAndInitialState() public view {
        // Test initial contract states
        assertEq(accessControl.isAdmin(admin), true);
        assertEq(accessControl.isHolder(holder1), true);
        assertEq(accessControl.isHolder(holder2), true);
        assertEq(accessControl.isHolder(user1), false);
        
        assertEq(holders.getHolderCount(), 0);
        assertEq(designers.getDesignerCount(), 0);
        assertEq(appraisals.getNFTCount(), 0);
        assertEq(reactionPacks.get_packCount(), 0);
        
        assertEq(reactionPacks.defaultBasePrice(), BASE_PRICE);
        assertEq(reactionPacks.defaultPriceIncrement(), PRICE_INCREMENT);
    }

    function testTokenBalances() public view {
        assertEq(podeToken.balanceOf(holder1), 1);
        assertEq(podeToken.balanceOf(holder2), 1);
        assertEq(podeToken.balanceOf(user1), 0);
        
        assertEq(monaToken.balanceOf(holder1), 10000 * 10**18);
        assertEq(monaToken.balanceOf(holder2), 10000 * 10**18);
        assertEq(monaToken.balanceOf(user1), 10000 * 10**18);
    }

    function testContractReferences() public view {
        assertEq(address(holders.accessControl()), address(accessControl));
        assertEq(address(designers.accessControl()), address(accessControl));
        assertEq(address(appraisals.accessControl()), address(accessControl));
        assertEq(address(reactionPacks.accessControl()), address(accessControl));
        
        assertEq(address(designers.holders()), address(holders));
        assertEq(address(appraisals.holders()), address(holders));
        
        assertEq(address(reactionPacks.designers()), address(designers));
        assertEq(address(reactionPacks.monaToken()), address(monaToken));
    }
}