// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract EndToEndTest is SetupTest {
    function testCompleteUserJourney() public {
        // Step 1: Ionic conductors register profiles
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1-profile");
        uint256 conductor1Id = conductors
            .getConductorByWallet(conductor1)
            .conductorId;

        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2-profile");
        uint256 conductor2Id = conductors
            .getConductorByWallet(conductor2)
            .conductorId;

        // Verify initial state
        IonicLibrary.Conductor memory conductor1Data = conductors
            .getConductorByWallet(conductor1);
        assertEq(conductor1Data.stats.availableInvites, 1);
        assertEq(conductors.getConductorCount(), 2);

        // Step 2: Conductor1 invites a designer
        vm.prank(conductor1);
        designers.inviteDesigner(designer1, conductor1Id);

        // Verify invite was consumed
        conductor1Data = conductors.getConductorByWallet(conductor1);
        assertEq(conductor1Data.stats.availableInvites, 0);
        assertEq(designers.isDesigner(designer1), true);

        // Step 3: Designer creates reaction packs
        string[] memory reactionUris = new string[](3);
        reactionUris[0] = "ipfs://fire-emoji";
        reactionUris[1] = "ipfs://heart-emoji";
        reactionUris[2] = "ipfs://star-emoji";

        vm.prank(designer1);
        uint256 packId = reactionPacks.createReactionPack(
            5, // maxEditions
            2, // conductorReservedSpots
            "ipfs://emoji-pack-metadata",
            reactionUris
        );

        // Verify pack creation
        IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(
            packId
        );
        assertEq(pack.designer, designer1);
        assertEq(pack.maxEditions, 5);
        assertEq(pack.currentPrice, BASE_PRICE);
        assertEq(reactionPacks.getPackCount(), 1);

        // Step 4: Conductor2 purchases reaction pack
        uint256 conductor2BalanceBefore = monaToken.balanceOf(conductor2);
        uint256 designerBalanceBefore = monaToken.balanceOf(designer1);

        vm.prank(conductor2);
        monaToken.approve(address(reactionPacks), pack.currentPrice);
        vm.prank(conductor2);
        reactionPacks.purchaseReactionPack(packId);

        // Verify purchase
        assertEq(reactionPacks.balanceOf(conductor2), 3); // 3 reaction NFTs
        uint256[] memory conductor2Purchases = reactionPacks.getBuyerPurchases(
            conductor2
        );
        assertEq(conductor2Purchases.length, 1); // 1 pack purchased

        // Verify payment transfer
        assertEq(
            monaToken.balanceOf(conductor2),
            conductor2BalanceBefore - BASE_PRICE
        );
        assertEq(
            monaToken.balanceOf(designer1),
            designerBalanceBefore + BASE_PRICE
        );

        // Verify pack state updated
        pack = reactionPacks.getReactionPack(packId);
        assertEq(pack.soldCount, 1);
        assertEq(pack.currentPrice, BASE_PRICE + PRICE_INCREMENT);

        // Step 5: Conductor1 submits an NFT for appraisal
        vm.prank(conductor1);
        uint256 nftId = appraisals.submitNFT(
            1, // tokenId
            address(ionicToken),
            IonicLibrary.TokenType.ERC721
        );

        // Verify NFT submission
        IonicLibrary.NFT memory nft = appraisals.getNFT(nftId);
        assertEq(nft.submitter, conductor1);
        assertEq(nft.nftContract, address(ionicToken));
        assertEq(nft.active, true);
        assertEq(appraisals.getNFTCount(), 1);

        // Step 6: Conductor2 appraises the NFT (using their reaction pack)
        vm.prank(conductor2);
        appraisals.createAppraisal(
            address(ionicToken),
            nftId,
            conductor2Id,
            87, // score
            "ipfs://detailed-appraisal",
            new IonicLibrary.ReactionUsage[](0) // Simple test without reactions
        );

        // Verify appraisal
        IonicLibrary.Appraisal memory appraisal = appraisals.getAppraisal(1);
        assertEq(appraisal.appraiser, conductor2);
        assertEq(appraisal.nftId, nftId);
        assertEq(appraisal.overallScore, 87);
        assertEq(appraisals.getAppraisalCount(), 1);

        // Verify NFT stats updated
        nft = appraisals.getNFT(nftId);
        assertEq(nft.appraisalCount, 1);
        assertEq(nft.averageScore, 87);

        // Verify conductor2 stats updated (conductor2 did the appraisal)
        IonicLibrary.Conductor memory conductor2AfterAppraisal = conductors
            .getConductorByWallet(conductor2);
        assertEq(conductor2AfterAppraisal.stats.appraisalCount, 1);
        assertEq(conductor2AfterAppraisal.stats.averageScore, 87);

        // Step 7: Conductor2 gives review feedback to Conductor1
        vm.prank(conductor2);
        conductors.submitReview(
            conductor1Id,
            95, // review score
            "ipfs://review-feedback",
            new IonicLibrary.ReactionUsage[](0)
        );

        // Verify review submission
        assertEq(conductors.getReviewCount(), 1);

        // Verify conductor1's review stats (conductor1 received review feedback)
        IonicLibrary.Conductor memory conductor1AfterReview = conductors
            .getConductorByWallet(conductor1);
        assertEq(conductor1AfterReview.stats.reviewCount, 1);
        assertEq(conductor1AfterReview.stats.averageReviewScore, 95);

        // Step 8: Generate more appraisals to earn invites
        for (uint256 i = 2; i <= 10; i++) {
            // Create new NFT
            vm.prank(conductor1);
            uint256 newNftId = appraisals.submitNFT(
                i,
                address(ionicToken),
                IonicLibrary.TokenType.ERC721
            );

            // Get third conductor for appraisals
            if (i == 2) {
                vm.prank(admin);
                ionicToken.mint(user1, 1);
                vm.prank(user1);
                conductors.registerProfile("ipfs://user1-profile");
            }

            // Have conductor2 do all appraisals to reach 10 total (1 initial + 9 more = 10)
            address appraiser = conductor2;
            uint256 appraiserId = conductor2Id;

            vm.prank(appraiser);
            appraisals.createAppraisal(
                address(ionicToken),
                newNftId,
                appraiserId,
                80 + (i % 20), // Vary scores
                string(abi.encodePacked("ipfs://appraisal-", i)),
                new IonicLibrary.ReactionUsage[](0)
            );
        }

        // Step 9: Verify invite economy - conductor2 should get +1 invite after 10 appraisals
        IonicLibrary.Conductor memory conductor2AfterAppraisals = conductors
            .getConductorByWallet(conductor2);
        assertEq(conductor2AfterAppraisals.stats.appraisalCount, 10);
        assertEq(conductor2AfterAppraisals.stats.availableInvites, 2); // Started with 1, earned 1 more = 2 total

        // Step 10: Use the earned invite to invite another designer
        vm.prank(admin);
        ionicToken.mint(user2, 1);

        vm.prank(conductor2);
        designers.inviteDesigner(user2, conductor2Id);

        // Verify second designer invitation
        assertEq(designers.isDesigner(user2), true);
        assertEq(designers.getDesignerCount(), 2);

        IonicLibrary.Conductor memory conductor2AfterInvite = conductors
            .getConductorByWallet(conductor2);
        assertEq(conductor2AfterInvite.stats.availableInvites, 1); // Had 2, used 1, left with 1
        assertEq(conductor2AfterInvite.stats.inviteCount, 1); // Total invites made by conductor2

        // Step 11: Test progressive pricing with multiple buyers
        string[] memory pack2Uris = new string[](1);
        pack2Uris[0] = "ipfs://premium-reaction";

        vm.prank(user2);
        uint256 pack2Id = reactionPacks.createReactionPack(
            3,
            1,
            "ipfs://premium-pack",
            pack2Uris
        );

        // Multiple purchases to test progressive pricing
        address[3] memory buyers = [conductor1, conductor2, user1];
        uint256 expectedPrice = BASE_PRICE;

        for (uint256 i = 0; i < 3; i++) {
            IonicLibrary.ReactionPack memory packBefore = reactionPacks
                .getReactionPack(pack2Id);
            assertEq(packBefore.currentPrice, expectedPrice);

            vm.prank(buyers[i]);
            monaToken.approve(address(reactionPacks), expectedPrice);
            vm.prank(buyers[i]);
            reactionPacks.purchaseReactionPack(pack2Id);

            expectedPrice += PRICE_INCREMENT;
        }

        // Verify final pack state
        IonicLibrary.ReactionPack memory pack2Final = reactionPacks
            .getReactionPack(pack2Id);
        assertEq(pack2Final.soldCount, 3);
        assertEq(pack2Final.maxEditions, 3); // Should be sold out

        // Step 12: Test sold out scenario
        vm.prank(admin);
        ionicToken.mint(admin, 1);
        vm.prank(admin);
        conductors.registerProfile("ipfs://admin");

        IonicLibrary.ReactionPack memory soldOutPack = reactionPacks
            .getReactionPack(pack2Id);
        vm.prank(admin);
        monaToken.approve(address(reactionPacks), soldOutPack.currentPrice);
        vm.prank(admin);
        vm.expectRevert(IonicErrors.SoldOut.selector);
        reactionPacks.purchaseReactionPack(pack2Id);

        // Final verification - complete system state
        assertEq(conductors.getConductorCount(), 4); // conductor1, conductor2, user1, admin
        assertEq(designers.getDesignerCount(), 2); // designer1, user2
        assertEq(appraisals.getNFTCount(), 10); // 10 NFTs submitted
        assertEq(appraisals.getAppraisalCount(), 10); // 10 appraisals created
        assertEq(reactionPacks.getPackCount(), 2); // 2 reaction packs created

        // Verify final stats for both conductors
        IonicLibrary.Conductor memory conductor1VeryFinal = conductors
            .getConductorByWallet(conductor1);
        assertEq(conductor1VeryFinal.stats.appraisalCount, 0); // conductor1 doesn't do appraisals
        assertEq(conductor1VeryFinal.stats.reviewCount, 1); // conductor1 received review feedback
        assertEq(conductor1VeryFinal.stats.inviteCount, 1); // conductor1 invited 1 designer initially
        assertEq(conductor1VeryFinal.stats.availableInvites, 0);
        assertEq(conductor1VeryFinal.stats.averageScore, 0); // no appraisals done
        assertEq(conductor1VeryFinal.stats.averageReviewScore, 95);

        IonicLibrary.Conductor memory conductor2VeryFinal = conductors
            .getConductorByWallet(conductor2);
        assertEq(conductor2VeryFinal.stats.appraisalCount, 10); // conductor2 did 10 appraisals
        assertEq(conductor2VeryFinal.stats.inviteCount, 1); // conductor2 invited 1 designer
        assertEq(conductor2VeryFinal.stats.availableInvites, 1); // earned 1, used 1, still has 1
        assertGt(conductor2VeryFinal.stats.averageScore, 0); // has appraisal average
    }

    function testReactionPackEconomics() public {
        // Test the full economic flow of reaction packs
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        uint256 conductor1Id = conductors
            .getConductorByWallet(conductor1)
            .conductorId;

        vm.prank(conductor1);
        designers.inviteDesigner(designer1, conductor1Id);

        string[] memory uris = new string[](2);
        uris[0] = "ipfs://reaction1";
        uris[1] = "ipfs://reaction2";

        vm.prank(designer1);
        uint256 packId = reactionPacks.createReactionPack(
            5,
            2,
            "ipfs://pack",
            uris
        );

        uint256 totalRevenue = 0;

        // Test multiple purchases with progressive pricing
        for (uint256 i = 0; i < 3; i++) {
            address buyer = i == 0 ? conductor1 : (i == 1 ? conductor2 : admin);

            if (buyer != conductor1) {
                vm.prank(admin);
                ionicToken.mint(buyer, 1);
                vm.prank(buyer);
                conductors.registerProfile(
                    string(abi.encodePacked("ipfs://buyer-", i))
                );
            }

            IonicLibrary.ReactionPack memory pack = reactionPacks
                .getReactionPack(packId);
            uint256 currentPrice = pack.currentPrice;
            totalRevenue += currentPrice;

            vm.prank(buyer);
            monaToken.approve(address(reactionPacks), currentPrice);
            vm.prank(buyer);
            reactionPacks.purchaseReactionPack(packId);

            // Verify buyer received tokens
            assertEq(reactionPacks.balanceOf(buyer), 2); // 2 reactions per pack
        }

        // Verify designer received revenue (minus revenue sharing to early buyers)
        uint256 designerFinalBalance = monaToken.balanceOf(designer1);
        assertEq(designerFinalBalance, 307e18); // Expected after revenue sharing

        // Verify pack tracking
        IonicLibrary.ReactionPack memory finalPack = reactionPacks
            .getReactionPack(packId);
        assertEq(finalPack.soldCount, 3);
        assertEq(finalPack.buyers.length, 3);

        // Verify revenue sharing calculation (early buyers get better deals)
        uint256 firstBuyerShare = finalPack.buyerShares[0];
        uint256 lastBuyerShare = finalPack.buyerShares[2];
        assertGt(firstBuyerShare, lastBuyerShare);
    }

    function testDesignerLifecycle() public {
        // Test complete designer lifecycle including deactivation
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        uint256 conductor1Id = conductors
            .getConductorByWallet(conductor1)
            .conductorId;

        // Invite designer
        vm.prank(conductor1);
        designers.inviteDesigner(designer1, conductor1Id);

        IonicLibrary.Conductor memory conductor1Before = conductors
            .getConductorByWallet(conductor1);
        uint256 invitesBefore = conductor1Before.stats.availableInvites;

        // Designer creates content
        string[] memory uris = new string[](1);
        uris[0] = "ipfs://reaction";

        vm.prank(designer1);
        uint256 packId = reactionPacks.createReactionPack(
            5,
            1,
            "ipfs://pack",
            uris
        );

        assertEq(designers.isDesigner(designer1), true);

        // Admin deactivates designer
        IonicLibrary.Designer memory designerData = designers
            .getDesignerByWallet(designer1);
        vm.prank(admin);
        designers.deactivateDesigner(designerData.designerId);

        // Verify deactivation
        assertEq(designers.isDesigner(designer1), false);

        // Verify invite returned to conductor
        IonicLibrary.Conductor memory conductor1After = conductors
            .getConductorByWallet(conductor1);
        assertEq(conductor1After.stats.availableInvites, invitesBefore + 1);

        // Verify existing packs still work but designer can't create new ones
        IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(
            packId
        );
        assertEq(pack.active, true);

        vm.prank(designer1);
        vm.expectRevert(IonicErrors.DesignerNotFound.selector);
        reactionPacks.createReactionPack(3, 1, "ipfs://new-pack", uris);
    }

    function testBasicUserFlow() public {
        // Simple end-to-end flow: register conductors, invite designer, create pack, purchase, submit NFT, appraise

        // 1. Conductors register
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        uint256 conductor1Id = conductors
            .getConductorByWallet(conductor1)
            .conductorId;

        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        uint256 conductor2Id = conductors
            .getConductorByWallet(conductor2)
            .conductorId;

        assertEq(conductors.getConductorCount(), 2);

        // 2. Conductor invites designer
        vm.prank(conductor1);
        designers.inviteDesigner(designer1, conductor1Id);

        assertEq(designers.isDesigner(designer1), true);

        // 3. Designer creates reaction pack
        string[] memory uris = new string[](2);
        uris[0] = "ipfs://fire";
        uris[1] = "ipfs://heart";

        vm.prank(designer1);
        uint256 packId = reactionPacks.createReactionPack(
            5,
            2,
            "ipfs://pack",
            uris
        );

        assertEq(reactionPacks.getPackCount(), 1);

        // 4. Conductor purchases pack
        IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(
            packId
        );
        vm.prank(conductor2);
        monaToken.approve(address(reactionPacks), pack.currentPrice);
        vm.prank(conductor2);
        reactionPacks.purchaseReactionPack(packId);

        assertEq(reactionPacks.balanceOf(conductor2), 2); // 2 reactions

        // 5. Conductor submits NFT
        vm.prank(conductor1);
        uint256 nftId = appraisals.submitNFT(
            1,
            address(ionicToken),
            IonicLibrary.TokenType.ERC721
        );

        assertEq(appraisals.getNFTCount(), 1);

        // 6. Other conductor appraises NFT
        vm.prank(conductor2);
        appraisals.createAppraisal(
            address(ionicToken),
            nftId,
            conductor2Id,
            85,
            "ipfs://appraisal",
            new IonicLibrary.ReactionUsage[](0)
        );

        assertEq(appraisals.getAppraisalCount(), 1);

        // 7. Verify final state
        IonicLibrary.NFT memory nft = appraisals.getNFT(nftId);
        assertEq(nft.averageScore, 85);
        assertEq(nft.appraisalCount, 1);

        IonicLibrary.Conductor memory conductor2Final = conductors
            .getConductorByWallet(conductor2);
        assertEq(conductor2Final.stats.appraisalCount, 1);
        assertEq(conductor2Final.stats.averageScore, 85);

        // System works end-to-end! ✅
    }

    function testProgressivePricingSimple() public {
        // Test progressive pricing in isolation

        // Setup
        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        uint256 conductor1Id = conductors
            .getConductorByWallet(conductor1)
            .conductorId;

        vm.prank(conductor1);
        designers.inviteDesigner(designer1, conductor1Id);

        string[] memory uris = new string[](1);
        uris[0] = "ipfs://reaction";

        vm.prank(designer1);
        uint256 packId = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack",
            uris
        );

        // Test progressive pricing
        IonicLibrary.ReactionPack memory pack1 = reactionPacks.getReactionPack(
            packId
        );
        assertEq(pack1.currentPrice, BASE_PRICE);

        vm.prank(conductor1);
        monaToken.approve(address(reactionPacks), pack1.currentPrice);
        vm.prank(conductor1);
        reactionPacks.purchaseReactionPack(packId);

        IonicLibrary.ReactionPack memory pack2 = reactionPacks.getReactionPack(
            packId
        );
        assertEq(pack2.currentPrice, BASE_PRICE + PRICE_INCREMENT);
        assertEq(pack2.soldCount, 1);

        // Progressive pricing works! ✅
    }

    function testInviteEconomySimple() public {
        // Test invite economy in isolation

        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        uint256 conductor1Id = conductors
            .getConductorByWallet(conductor1)
            .conductorId;

        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        uint256 conductor2Id = conductors
            .getConductorByWallet(conductor2)
            .conductorId;

        // Use initial invite
        IonicLibrary.Conductor memory conductor1Before = conductors
            .getConductorByWallet(conductor1);
        assertEq(conductor1Before.stats.availableInvites, 1);

        vm.prank(conductor1);
        designers.inviteDesigner(designer1, conductor1Id);

        IonicLibrary.Conductor memory conductor1After = conductors
            .getConductorByWallet(conductor1);
        assertEq(conductor1After.stats.availableInvites, 0);

        // Create 10 appraisals to earn new invite
        for (uint256 i = 1; i <= 10; i++) {
            vm.prank(conductor1);
            uint256 nftId = appraisals.submitNFT(
                i,
                address(ionicToken),
                IonicLibrary.TokenType.ERC721
            );

            vm.prank(conductor2);
            appraisals.createAppraisal(
                address(ionicToken),
                nftId,
                conductor2Id,
                80,
                string(abi.encodePacked("ipfs://appraisal-", i)),
                new IonicLibrary.ReactionUsage[](0)
            );
        }

        // Check if invite was earned by conductor2 (who did all the appraisals)
        IonicLibrary.Conductor memory conductor2Final = conductors
            .getConductorByWallet(conductor2);
        assertEq(conductor2Final.stats.appraisalCount, 10);
        assertEq(conductor2Final.stats.availableInvites, 2); // Started with 1, earned 1 more = 2 total

        // Invite economy works! ✅
    }
}
