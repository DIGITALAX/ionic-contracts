// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract EndToEndTest is SetupTest {
    function testCompleteUserJourney() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor2);
        conductors.updateProfile(2, "ipfs://conductor2");
        uint256 c2Id = conductors.getConductorId(conductor2);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, designer1);

        string[] memory uris = new string[](1);
        uris[0] = "ipfs://reaction";

        vm.prank(designer1);
        uint256 packId = reactionPacks.createReactionPack(5, 2, "ipfs://pack", uris);

        vm.prank(conductor2);
        monaToken.approve(address(reactionPacks), 100e18);
        vm.prank(conductor2);
        reactionPacks.purchaseReactionPack(packId);

        vm.prank(conductor1);
        uint256 nftId = appraisals.submitNFT(1, address(ionicToken), IonicLibrary.TokenType.ERC721);

        vm.prank(conductor2);
        appraisals.createAppraisal(address(ionicToken), nftId, c2Id, 87, "ipfs://appraisal", new IonicLibrary.ReactionUsage[](0));

        vm.prank(conductor2);
        conductors.submitReview(c1Id, 95, "ipfs://review", new IonicLibrary.ReactionUsage[](0));
    }

    function testBasicPurchase() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, designer1);

        string[] memory uris = new string[](1);
        uris[0] = "ipfs://reaction";

        vm.prank(designer1);
        uint256 packId = reactionPacks.createReactionPack(10, 2, "ipfs://pack", uris);

        vm.prank(conductor2);
        monaToken.approve(address(reactionPacks), 100e18);
        vm.prank(conductor2);
        reactionPacks.purchaseReactionPack(packId);

        assertEq(reactionPacks.balanceOf(conductor2), 1);
    }

    function testAppraisal() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://c1");

        vm.prank(conductor2);
        conductors.updateProfile(2, "ipfs://c2");
        uint256 c2Id = conductors.getConductorId(conductor2);

        vm.prank(conductor1);
        uint256 nftId = appraisals.submitNFT(1, address(ionicToken), IonicLibrary.TokenType.ERC721);

        vm.prank(conductor2);
        appraisals.createAppraisal(address(ionicToken), nftId, c2Id, 85, "ipfs://appraisal", new IonicLibrary.ReactionUsage[](0));

        assertEq(appraisals.getAppraisalCount(), 1);
    }
}