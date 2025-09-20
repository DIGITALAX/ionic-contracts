// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./00-Setup.t.sol";

contract DesignersTest is SetupTest {
    
    function testInitialDesignerState() public view {
        assertEq(designers.designerCount(), 0);
        assertEq(designers.isDesigner(holder1), false);
        assertEq(designers.isDesigner(user1), false);
    }
    
    function testInviteDesigner() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        assertEq(designers.isDesigner(user1), true);
        assertEq(designers.designerCount(), 1);
        
        Library.Designer memory designer = designers.getDesigner(user1);
        assertEq(designer.wallet, user1);
        assertEq(designer.uri, "ipfs://designer1");
        assertEq(designer.invitedBy, holder1);
        assertEq(designer.isActive, true);
    }
    
    function testOnlyHoldersCanInviteDesigners() public {
        vm.prank(user1);
        vm.expectRevert(Errors.Unauthorized.selector);
        designers.inviteDesigner(user2, "ipfs://designer2");
    }
    
    function testHolderNeedsInvitesToInviteDesigner() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        Library.Holder memory holder = holders.getHolder(holder1);
        assertEq(holder.stats.availableInvites, 1);
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        holder = holders.getHolder(holder1);
        assertEq(holder.stats.availableInvites, 0);
        
        vm.prank(holder1);
        vm.expectRevert(Errors.InsufficientInvites.selector);
        designers.inviteDesigner(user2, "ipfs://designer2");
    }
    
    function testCannotInviteExistingDesigner() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        vm.prank(admin);
        holders.registerProfile(holder2, "ipfs://holder2", "holder2");
        
        vm.prank(holder2);
        vm.expectRevert(Errors.DesignerAlreadyExists.selector);
        designers.inviteDesigner(user1, "ipfs://designer1-updated");
    }
    
    function testUpdateDesignerProfile() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        vm.prank(user1);
        designers.updateDesignerProfile("ipfs://designer1-updated");
        
        Library.Designer memory designer = designers.getDesigner(user1);
        assertEq(designer.uri, "ipfs://designer1-updated");
    }
    
    function testOnlyDesignerCanUpdateOwnProfile() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        vm.prank(user2);
        vm.expectRevert(Errors.Unauthorized.selector);
        designers.updateDesignerProfile("ipfs://designer1-hacked");
    }
    
    function testDeactivateDesigner() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        assertEq(designers.isDesigner(user1), true);
        
        vm.prank(admin);
        designers.deactivateDesigner(user1);
        
        assertEq(designers.isDesigner(user1), false);
        
        Library.Designer memory designer = designers.getDesigner(user1);
        assertEq(designer.isActive, false);
    }
    
    function testOnlyAdminCanDeactivateDesigner() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        vm.prank(holder1);
        vm.expectRevert(Errors.Unauthorized.selector);
        designers.deactivateDesigner(user1);
    }
    
    function testInviteReturnedOnDeactivation() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        Library.Holder memory holderBefore = holders.getHolder(holder1);
        uint256 invitesBefore = holderBefore.stats.availableInvites;
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        Library.Holder memory holderAfterInvite = holders.getHolder(holder1);
        assertEq(holderAfterInvite.stats.availableInvites, invitesBefore - 1);
        
        vm.prank(admin);
        designers.deactivateDesigner(user1);
        
        Library.Holder memory holderAfterDeactivation = holders.getHolder(holder1);
        assertEq(holderAfterDeactivation.stats.availableInvites, invitesBefore);
    }
    
    function testCannotDeactivateNonExistentDesigner() public {
        vm.prank(admin);
        vm.expectRevert(Errors.DesignerNotFound.selector);
        designers.deactivateDesigner(user1);
    }
    
    function testMultipleDesignerInvitations() public {
        vm.prank(admin);
        holders.registerProfile(holder1, "ipfs://holder1", "holder1");
        
        vm.prank(admin);
        holders.registerProfile(holder2, "ipfs://holder2", "holder2");
        
        vm.prank(holder1);
        designers.inviteDesigner(user1, "ipfs://designer1");
        
        vm.prank(holder2);
        designers.inviteDesigner(user2, "ipfs://designer2");
        
        assertEq(designers.designerCount(), 2);
        assertEq(designers.isDesigner(user1), true);
        assertEq(designers.isDesigner(user2), true);
        
        Library.Designer memory designer1 = designers.getDesigner(user1);
        Library.Designer memory designer2 = designers.getDesigner(user2);
        
        assertEq(designer1.invitedBy, holder1);
        assertEq(designer2.invitedBy, holder2);
    }
}