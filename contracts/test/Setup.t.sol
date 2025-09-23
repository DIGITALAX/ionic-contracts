// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/IonicAccessControl.sol";
import "../src/IonicConductors.sol";
import "../src/IonicDesigners.sol";
import "../src/IonicAppraisals.sol";
import "../src/IonicReactionPacks.sol";
import "../src/TestERC20.sol";
import "../src/TestERC721.sol";
import "../src/IonicLibrary.sol";

contract SetupTest is Test {
    IonicAccessControl public accessControl;
    IonicConductors public conductors;
    IonicDesigners public designers;
    IonicAppraisals public appraisals;
    IonicReactionPacks public reactionPacks;
    TestERC20 public monaToken;
    TestERC721 public ionicToken;

    address public admin = address(0x1);
    address public conductor1 = address(0x2);
    address public conductor2 = address(0x3);
    address public designer1 = address(0x4);
    address public user1 = address(0x5);
    address public user2 = address(0x6);

    uint256 public constant BASE_PRICE = 100 * 10**18; // 100 MONA
    uint256 public constant PRICE_INCREMENT = 10 * 10**18; // 10 MONA

    function setUp() public virtual {
        vm.startPrank(admin);
        
        // Deploy tokens
        monaToken = new TestERC20();
        ionicToken = new TestERC721();
        
        // Deploy core contracts
        accessControl = new IonicAccessControl(address(monaToken));
        conductors = new IonicConductors(address(accessControl));
        designers = new IonicDesigners(address(accessControl), address(conductors));
        appraisals = new IonicAppraisals(address(accessControl), address(conductors));
        reactionPacks = new IonicReactionPacks(
            address(accessControl),
            address(designers),
            BASE_PRICE,
            PRICE_INCREMENT
        );
        
        // Set contract references
        accessControl.setIonicToken(address(ionicToken));
        conductors.setAppraisals(address(appraisals));
        conductors.setDesigners(address(designers));
        conductors.setReactionPacks(address(reactionPacks));
        appraisals.setReactionPacks(address(reactionPacks));
        
        // Mint tokens for testing
        ionicToken.mint(conductor1, 1);
        ionicToken.mint(conductor2, 1);
        
        monaToken.mint(conductor1, 10000 * 10**18);
        monaToken.mint(conductor2, 10000 * 10**18);
        monaToken.mint(user1, 10000 * 10**18);
        monaToken.mint(user2, 10000 * 10**18);
        
        vm.stopPrank();
    }

    function testDeploymentAndInitialState() public view virtual {
        // Test initial contract states
        assertEq(accessControl.isAdmin(admin), true);
        assertEq(accessControl.isConductor(conductor1), true);
        assertEq(accessControl.isConductor(conductor2), true);
        assertEq(accessControl.isConductor(user1), false);
        
        assertEq(conductors.getConductorCount(), 0);
        assertEq(designers.getDesignerCount(), 0);
        assertEq(appraisals.getNFTCount(), 0);
        assertEq(reactionPacks.getPackCount(), 0);
        
        assertEq(reactionPacks.defaultBasePrice(), BASE_PRICE);
        assertEq(reactionPacks.defaultPriceIncrement(), PRICE_INCREMENT);
    }

    function testTokenBalances() public view {
        assertEq(ionicToken.balanceOf(conductor1), 1);
        assertEq(ionicToken.balanceOf(conductor2), 1);
        assertEq(ionicToken.balanceOf(user1), 0);
        assertEq(ionicToken.balanceOf(user2), 0);
        
        assertEq(monaToken.balanceOf(conductor1), 10000 * 10**18);
        assertEq(monaToken.balanceOf(conductor2), 10000 * 10**18);
        assertEq(monaToken.balanceOf(user1), 10000 * 10**18);
        assertEq(monaToken.balanceOf(user2), 10000 * 10**18);
    }

    function testContractReferences() public view {
        assertEq(address(conductors.accessControl()), address(accessControl));
        assertEq(address(designers.accessControl()), address(accessControl));
        assertEq(address(appraisals.accessControl()), address(accessControl));
        assertEq(address(reactionPacks.accessControl()), address(accessControl));
        
        assertEq(address(designers.conductors()), address(conductors));
        assertEq(address(appraisals.conductors()), address(conductors));
        
        assertEq(address(reactionPacks.designers()), address(designers));
    }
}