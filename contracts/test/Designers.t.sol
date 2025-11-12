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
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

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
        designers.inviteDesigner(1, user2);
    }

    function testConductorNeedsInvitesToInviteDesigner() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        vm.prank(conductor1);
        vm.expectRevert(IonicErrors.NoInvitesAvailable.selector);
        designers.inviteDesigner(c1Id, user2);
    }

    function testCannotInviteExistingDesigner() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        vm.prank(conductor2);
        conductors.updateProfile(2, "ipfs://conductor2");
        uint256 c2Id = conductors.getConductorId(conductor2);

        vm.prank(conductor2);
        vm.expectRevert(IonicErrors.AlreadyExists.selector);
        designers.inviteDesigner(c2Id, user1);
    }


    function testDeactivateDesigner() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

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
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

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
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        IonicLibrary.Designer memory designerData = designers.getDesignerByWallet(user1);
        uint256 designerId = designerData.designerId;

        vm.prank(admin);
        designers.deactivateDesigner(designerId);
    }

    function testCannotDeactivateNonExistentDesigner() public {
        vm.prank(admin);
        vm.expectRevert(IonicErrors.DesignerNotFound.selector);
        designers.deactivateDesigner(999);
    }

    function testMultipleDesignerInvitations() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor2);
        conductors.updateProfile(2, "ipfs://conductor2");
        uint256 c2Id = conductors.getConductorId(conductor2);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        vm.prank(conductor2);
        designers.inviteDesigner(c2Id, user2);

        assertEq(designers.getDesignerCount(), 2);
        assertEq(designers.isDesigner(user1), true);
        assertEq(designers.isDesigner(user2), true);

        IonicLibrary.Designer memory designer1 = designers.getDesignerByWallet(user1);
        IonicLibrary.Designer memory designer2 = designers.getDesignerByWallet(user2);

        assertEq(designer1.invitedBy, conductor1);
        assertEq(designer2.invitedBy, conductor2);
    }
}