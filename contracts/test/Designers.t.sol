// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract DesignersTest is SetupTest {
    
    function testInitialDesignerState() public view {
        assertEq(designers.getDesignerCount(), 0);
        assertEq(designers.isDesigner(conductor1), false);
        assertEq(designers.isDesigner(user1), false);
    }
    
    function testInviteDesigner() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.Conductor memory conductor = conductors.getConductorByWallet(conductor1);
        uint256 conductorId = conductor.conductorId;
        
        vm.prank(conductor1);
        designers.inviteDesigner(user1, conductorId);
        
        assertEq(designers.isDesigner(user1), true);
        assertEq(designers.getDesignerCount(), 1);
        
        IonicLibrary.Designer memory designer = designers.getDesignerByWallet(user1);
        assertEq(designer.wallet, user1);
        assertEq(designer.invitedBy, conductor1);
        assertEq(designer.active, true);
    }
    
    function testOnlyConductorsCanInviteDesigners() public {
        vm.prank(user1);
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        designers.inviteDesigner(user2, 1);
    }
    
    function testConductorNeedsInvitesToInviteDesigner() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.Conductor memory conductor = conductors.getConductorByWallet(conductor1);
        uint256 conductorId = conductor.conductorId;
        assertEq(conductor.stats.availableInvites, 1);
        
        vm.prank(conductor1);
        designers.inviteDesigner(user1, conductorId);
        
        conductor = conductors.getConductorByWallet(conductor1);
        assertEq(conductor.stats.availableInvites, 0);
        
        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.NoInvitesAvailable.selector);
        designers.inviteDesigner(user2, conductorId);
    }
    
    function testCannotInviteExistingDesigner() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.Conductor memory conductor1Data = conductors.getConductorByWallet(conductor1);
        uint256 conductor1Id = conductor1Data.conductorId;
        
        vm.prank(conductor1);
        designers.inviteDesigner(user1, conductor1Id);
        
        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        
        IonicLibrary.Conductor memory conductor2Data = conductors.getConductorByWallet(conductor2);
        uint256 conductor2Id = conductor2Data.conductorId;
        
        vm.prank(conductor2);
        vm.expectRevert(IonicErrors.AlreadyExists.selector);
        designers.inviteDesigner(user1, conductor2Id);
    }
    
    
    function testDeactivateDesigner() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.Conductor memory conductor = conductors.getConductorByWallet(conductor1);
        uint256 conductorId = conductor.conductorId;
        
        vm.prank(conductor1);
        designers.inviteDesigner(user1, conductorId);
        
        assertEq(designers.isDesigner(user1), true);
        
        IonicLibrary.Designer memory designerData = designers.getDesignerByWallet(user1);
        uint256 designerId = designerData.designerId;
        
        vm.prank(admin);
        designers.deactivateDesigner(designerId);
        
        assertEq(designers.isDesigner(user1), false);
        
        IonicLibrary.Designer memory designer = designers.getDesignerByWallet(user1);
        assertEq(designer.active, false);
    }
    
    function testOnlyAdminOrInviterCanDeactivateDesigner() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.Conductor memory conductor = conductors.getConductorByWallet(conductor1);
        uint256 conductorId = conductor.conductorId;
        
        vm.prank(conductor1);
        designers.inviteDesigner(user1, conductorId);
        
        IonicLibrary.Designer memory designerData = designers.getDesignerByWallet(user1);
        uint256 designerId = designerData.designerId;
        
        vm.prank(user2);
        vm.expectRevert(IonicErrors.OnlyInviter.selector);
        designers.deactivateDesigner(designerId);
        
        vm.prank(conductor1);
        designers.deactivateDesigner(designerId);
        
        assertEq(designers.isDesigner(user1), false);
    }
    
    function testInviteReturnedOnDeactivation() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.Conductor memory conductorBefore = conductors.getConductorByWallet(conductor1);
        uint256 conductorId = conductorBefore.conductorId;
        uint256 invitesBefore = conductorBefore.stats.availableInvites;
        
        vm.prank(conductor1);
        designers.inviteDesigner(user1, conductorId);
        
        IonicLibrary.Conductor memory conductorAfterInvite = conductors.getConductorByWallet(conductor1);
        assertEq(conductorAfterInvite.stats.availableInvites, invitesBefore - 1);
        
        IonicLibrary.Designer memory designerData = designers.getDesignerByWallet(user1);
        uint256 designerId = designerData.designerId;
        
        vm.prank(admin);
        designers.deactivateDesigner(designerId);
        
        IonicLibrary.Conductor memory conductorAfterDeactivation = conductors.getConductorByWallet(conductor1);
        assertEq(conductorAfterDeactivation.stats.availableInvites, invitesBefore);
    }
    
    function testCannotDeactivateNonExistentDesigner() public {
        vm.prank(admin);
        vm.expectRevert(IonicErrors.DesignerNotFound.selector);
        designers.deactivateDesigner(999);
    }
    
    function testMultipleDesignerInvitations() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        
        IonicLibrary.Conductor memory conductor1Data = conductors.getConductorByWallet(conductor1);
        IonicLibrary.Conductor memory conductor2Data = conductors.getConductorByWallet(conductor2);
        uint256 conductor1Id = conductor1Data.conductorId;
        uint256 conductor2Id = conductor2Data.conductorId;
        
        vm.prank(conductor1);
        designers.inviteDesigner(user1, conductor1Id);
        
        vm.prank(conductor2);
        designers.inviteDesigner(user2, conductor2Id);
        
        assertEq(designers.getDesignerCount(), 2);
        assertEq(designers.isDesigner(user1), true);
        assertEq(designers.isDesigner(user2), true);
        
        IonicLibrary.Designer memory designer1 = designers.getDesignerByWallet(user1);
        IonicLibrary.Designer memory designer2 = designers.getDesignerByWallet(user2);
        
        assertEq(designer1.invitedBy, conductor1);
        assertEq(designer2.invitedBy, conductor2);
    }
}