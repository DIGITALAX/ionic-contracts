// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./00-Setup.t.sol";

contract AccessControlTest is SetupTest {
    
    function testInitialAdminState() public view {
        assertEq(accessControl.isAdmin(admin), true);
        assertEq(accessControl.isAdmin(holder1), false);
        assertEq(accessControl.isAdmin(user1), false);
    }
    
    function testInitialHolderState() public view {
        assertEq(accessControl.isHolder(holder1), true);
        assertEq(accessControl.isHolder(holder2), true);
        assertEq(accessControl.isHolder(user1), false);
        assertEq(accessControl.isHolder(admin), false);
    }
    
    function testOnlyAdminCanAddAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(user1);
        assertEq(accessControl.isAdmin(user1), true);
        
        vm.prank(holder1);
        vm.expectRevert(Errors.Unauthorized.selector);
        accessControl.addAdmin(holder2);
    }
    
    function testOnlyAdminCanRemoveAdmin() public {
        vm.prank(admin);
        accessControl.addAdmin(user1);
        assertEq(accessControl.isAdmin(user1), true);
        
        vm.prank(admin);
        accessControl.removeAdmin(user1);
        assertEq(accessControl.isAdmin(user1), false);
        
        vm.prank(holder1);
        vm.expectRevert(Errors.Unauthorized.selector);
        accessControl.removeAdmin(admin);
    }
    
    function testHolderStatusBasedOnTokenBalance() public {
        assertEq(accessControl.isHolder(user1), false);
        
        vm.prank(admin);
        podeToken.mint(user1, 1);
        uint256 tokenId = podeToken.getCurrentTokenId();
        assertEq(accessControl.isHolder(user1), true);
        
        vm.prank(user1);
        podeToken.safeTransferFrom(user1, admin, tokenId);
        assertEq(accessControl.isHolder(user1), false);
    }
    
    function testMultipleTokensStillHolder() public {
        vm.prank(admin);
        podeToken.mint(holder1, 1);
        uint256 newTokenId = podeToken.getCurrentTokenId();
        assertEq(accessControl.isHolder(holder1), true);
        assertEq(podeToken.balanceOf(holder1), 2);
        
        vm.prank(holder1);
        podeToken.safeTransferFrom(holder1, user1, newTokenId);
        assertEq(accessControl.isHolder(holder1), true);
        assertEq(accessControl.isHolder(user1), true);
    }
    
    function testOnlyAdminCanSetPodeToken() public {
        address newTokenAddress = address(0x999);
        
        vm.prank(admin);
        accessControl.setPodeToken(newTokenAddress);
        assertEq(accessControl.podeToken(), newTokenAddress);
        
        vm.prank(holder1);
        vm.expectRevert(Errors.Unauthorized.selector);
        accessControl.setPodeToken(address(podeToken));
    }
    
    function testOnlyAdminCanSetMonaToken() public {
        address newTokenAddress = address(0x888);
        
        vm.prank(admin);
        accessControl.setMonaToken(newTokenAddress);
        assertEq(address(accessControl.monaToken()), newTokenAddress);
        
        vm.prank(holder1);
        vm.expectRevert(Errors.Unauthorized.selector);
        accessControl.setMonaToken(address(monaToken));
    }
}