// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./00-Setup.t.sol";

contract HoldersTest is SetupTest {
    
    function testRegisterProfile() public {
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1-profile");
        
        assertEq(holders.getHolderCount(), 1);
        
        Library.Holder memory holder = holders.getHolder(1);
        assertEq(holder.wallet, holder1);
        assertEq(holder.holderId, 1);
        assertEq(holder.uri, "ipfs://holder1-profile");
        assertEq(holder.stats.appraisalCount, 0);
        assertEq(holder.stats.availableInvites, 1);
        assertEq(holder.stats.inviteCount, 0);
    }

    function testRegisterMultipleProfiles() public {
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1");
        
        vm.prank(holder2);
        holders.registerProfile("ipfs://holder2");
        
        assertEq(holders.getHolderCount(), 2);
        
        Library.Holder memory holder1Data = holders.getHolder(1);
        Library.Holder memory holder2Data = holders.getHolder(2);
        
        assertEq(holder1Data.wallet, holder1);
        assertEq(holder2Data.wallet, holder2);
        assertEq(holder1Data.holderId, 1);
        assertEq(holder2Data.holderId, 2);
    }

    function testOnlyHoldersCanRegister() public {
        vm.prank(user1); // user1 has no PODE token
        vm.expectRevert(Errors.Unauthorized.selector);
        holders.registerProfile("ipfs://user1");
    }

    function testUpdateProfile() public {
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1-v1");
        
        vm.prank(holder1);
        holders.updateProfile(1, "ipfs://holder1-v2");
        
        Library.Holder memory holder = holders.getHolder(1);
        assertEq(holder.uri, "ipfs://holder1-v2");
    }

    function testSubmitTrust() public {
        // Register two holders
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1");
        
        vm.prank(holder2);
        holders.registerProfile("ipfs://holder2");
        
        // Submit trust score with empty reactions
        Library.ReactionUsage[] memory reactions = new Library.ReactionUsage[](0);
        
        vm.prank(holder2);
        holders.submitTrust(1, 75, "ipfs://trust-comment", reactions);
        
        assertEq(holders.getTrustCount(), 1);
        
        Library.Holder memory holder1Data = holders.getHolder(1);
        assertEq(holder1Data.stats.trustCount, 1);
        assertEq(holder1Data.stats.totalTrustScore, 75);
        assertEq(holder1Data.stats.averageTrustScore, 75);
    }

    function testSubmitMultipleTrustScores() public {
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1");
        
        vm.prank(holder2);
        holders.registerProfile("ipfs://holder2");
        
        Library.ReactionUsage[] memory reactions = new Library.ReactionUsage[](0);
        
        // Submit multiple trust scores for holder1
        vm.prank(holder2);
        holders.submitTrust(1, 80, "ipfs://trust1", reactions);
        
        vm.prank(holder2);
        holders.submitTrust(1, 60, "ipfs://trust2", reactions);
        
        Library.Holder memory holder1Data = holders.getHolder(1);
        assertEq(holder1Data.stats.trustCount, 2);
        assertEq(holder1Data.stats.totalTrustScore, 140);
        assertEq(holder1Data.stats.averageTrustScore, 70);
    }

    function testInvalidTrustScore() public {
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1");
        
        Library.ReactionUsage[] memory reactions = new Library.ReactionUsage[](0);
        
        // Try to submit trust score out of range
        vm.prank(holder2);
        vm.expectRevert(Errors.InvalidTrustScore.selector);
        holders.submitTrust(1, 0, "ipfs://trust", reactions);
        
        vm.prank(holder2);
        vm.expectRevert(Errors.InvalidTrustScore.selector);
        holders.submitTrust(1, 101, "ipfs://trust", reactions);
    }

    function testGetHolderByWallet() public {
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1");
        
        Library.Holder memory holder = holders.getHolderByWallet(holder1);
        assertEq(holder.wallet, holder1);
        assertEq(holder.holderId, 1);
        
        vm.expectRevert(Errors.HolderNotFound.selector);
        holders.getHolderByWallet(user1);
    }

    function testDeleteProfile() public {
        vm.prank(holder1);
        holders.registerProfile("ipfs://holder1");
        
        vm.prank(holder1);
        holders.deleteProfile(1);
        
        // Profile should be deleted (all fields zeroed)
        Library.Holder memory holder = holders.getHolder(1);
        assertEq(holder.wallet, address(0));
        assertEq(holder.holderId, 0);
    }
}