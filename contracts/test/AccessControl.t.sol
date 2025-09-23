// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract AccessControlTest is SetupTest {
    
    function testInitialAdminState() public view {
        assertEq(accessControl.isAdmin(admin), true);
        assertEq(accessControl.isAdmin(conductor1), false);
        assertEq(accessControl.isAdmin(user1), false);
    }
    
    function testInitialConductorState() public view {
        assertEq(accessControl.isConductor(conductor1), true);
        assertEq(accessControl.isConductor(conductor2), true);
        assertEq(accessControl.isConductor(user1), false);
        assertEq(accessControl.isConductor(admin), false);
    }
    
    function testOnlyAdminCanAddAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(user1);
        assertEq(accessControl.isAdmin(user1), true);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.addAdmin(conductor2);
    }
    
    function testOnlyAdminCanRemoveAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(user1);
        assertEq(accessControl.isAdmin(user1), true);
        
        vm.prank(admin);
        accessControl.removeAdmin(user1);
        assertEq(accessControl.isAdmin(user1), false);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.removeAdmin(admin);
    }
    
    function testConductorStatusBasedOnTokenBalance() public {
        assertEq(accessControl.isConductor(user1), false);
        
        vm.prank(admin);
        ionicToken.mint(user1, 1);
        uint256 tokenId = ionicToken.getCurrentTokenId();
        assertEq(accessControl.isConductor(user1), true);
        
        vm.prank(user1);
        ionicToken.safeTransferFrom(user1, admin, tokenId);
        assertEq(accessControl.isConductor(user1), false);
    }
    
    function testMultipleTokensStillConductor() public {
        vm.prank(admin);
        ionicToken.mint(conductor1, 1);
        uint256 newTokenId = ionicToken.getCurrentTokenId();
        assertEq(accessControl.isConductor(conductor1), true);
        assertEq(ionicToken.balanceOf(conductor1), 2);
        
        vm.prank(conductor1);
        ionicToken.safeTransferFrom(conductor1, user1, newTokenId);
        assertEq(accessControl.isConductor(conductor1), true);
        assertEq(accessControl.isConductor(user1), true);
    }
    
    function testOnlyAdminCanSetIonicToken() public {
        address newTokenAddress = address(0x999);
        
        vm.prank(admin);
        accessControl.setIonicToken(newTokenAddress);
        assertEq(accessControl.ionicToken(), newTokenAddress);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.setIonicToken(address(ionicToken));
    }
    
    function testOnlyAdminCanSetMonaToken() public {
        address newTokenAddress = address(0x888);
        
        vm.prank(admin);
        accessControl.setMonaToken(newTokenAddress);
        assertEq(address(accessControl.monaToken()), newTokenAddress);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        accessControl.setMonaToken(address(monaToken));
    }
}