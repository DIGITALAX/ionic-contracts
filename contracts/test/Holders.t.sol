// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract ConductorsTest is SetupTest {
    
    function testRegisterProfile() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1-profile");
        
        assertEq(conductors.getConductorCount(), 1);
        
        IonicLibrary.Conductor memory conductor = conductors.getConductor(1);
        assertEq(conductor.wallet, conductor1);
        assertEq(conductor.conductorId, 1);
        assertEq(conductor.uri, "ipfs://conductor1-profile");
        assertEq(conductor.stats.appraisalCount, 0);
        assertEq(conductor.stats.availableInvites, 1);
        assertEq(conductor.stats.inviteCount, 0);
    }

    function testRegisterMultipleProfiles() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        
        assertEq(conductors.getConductorCount(), 2);
        
        IonicLibrary.Conductor memory conductor1Data = conductors.getConductor(1);
        IonicLibrary.Conductor memory conductor2Data = conductors.getConductor(2);
        
        assertEq(conductor1Data.wallet, conductor1);
        assertEq(conductor2Data.wallet, conductor2);
        assertEq(conductor1Data.conductorId, 1);
        assertEq(conductor2Data.conductorId, 2);
    }

    function testOnlyConductorsCanRegister() public {
        vm.prank(user1); // user1 has no Ionic token
        vm.expectRevert(IonicErrors.Unauthorized.selector);
        conductors.registerProfile("ipfs://user1");
    }

    function testUpdateProfile() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1-v1");
        
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1-v2");
        
        IonicLibrary.Conductor memory conductor = conductors.getConductor(1);
        assertEq(conductor.uri, "ipfs://conductor1-v2");
    }

    function testSubmitReview() public {
        // Register two conductors
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        
        // Submit review score with empty reactions
        IonicLibrary.ReactionUsage[] memory reactions = new IonicLibrary.ReactionUsage[](0);
        
        vm.prank(conductor2);
        conductors.submitReview(1, 75, "ipfs://review-comment", reactions);
        
        assertEq(conductors.getReviewCount(), 1);
        
        IonicLibrary.Conductor memory conductor1Data = conductors.getConductor(1);
        assertEq(conductor1Data.stats.reviewCount, 1);
        assertEq(conductor1Data.stats.totalReviewScore, 75);
        assertEq(conductor1Data.stats.averageReviewScore, 75);
    }

    function testSubmitMultipleReviewScores() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        
        IonicLibrary.ReactionUsage[] memory reactions = new IonicLibrary.ReactionUsage[](0);
        
        // Submit multiple review scores for conductor1
        vm.prank(conductor2);
        conductors.submitReview(1, 80, "ipfs://review1", reactions);
        
        vm.prank(conductor2);
        conductors.submitReview(1, 60, "ipfs://review2", reactions);
        
        IonicLibrary.Conductor memory conductor1Data = conductors.getConductor(1);
        assertEq(conductor1Data.stats.reviewCount, 2);
        assertEq(conductor1Data.stats.totalReviewScore, 140);
        assertEq(conductor1Data.stats.averageReviewScore, 70);
    }

    function testInvalidReviewScore() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.ReactionUsage[] memory reactions = new IonicLibrary.ReactionUsage[](0);
        
        // Try to submit review score out of range
        vm.prank(conductor2);
        vm.expectRevert(IonicErrors.InvalidReviewScore.selector);
        conductors.submitReview(1, 0, "ipfs://review", reactions);
        
        vm.prank(conductor2);
        vm.expectRevert(IonicErrors.InvalidReviewScore.selector);
        conductors.submitReview(1, 101, "ipfs://review", reactions);
    }

    function testGetConductorByWallet() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        IonicLibrary.Conductor memory conductor = conductors.getConductorByWallet(conductor1);
        assertEq(conductor.wallet, conductor1);
        assertEq(conductor.conductorId, 1);
        
        vm.expectRevert(IonicErrors.ConductorNotFound.selector);
        conductors.getConductorByWallet(user1);
    }

    function testDeleteProfile() public {
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        
        vm.prank(conductor1);
        conductors.deleteProfile(1);
        
        // Profile should be deleted (all fields zeroed)
        IonicLibrary.Conductor memory conductor = conductors.getConductor(1);
        assertEq(conductor.wallet, address(0));
        assertEq(conductor.conductorId, 0);
    }
}