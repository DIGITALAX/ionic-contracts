// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract AppraisalsTest is SetupTest {
    uint256 conductor1Id;
    uint256 conductor2Id;
    uint256 nftId;

    function setUp() public override {
        super.setUp();

        vm.prank(conductor1);
        conductors.registerProfile("ipfs://conductor1");
        conductor1Id = conductors.getConductorByWallet(conductor1).conductorId;

        vm.prank(conductor2);
        conductors.registerProfile("ipfs://conductor2");
        conductor2Id = conductors.getConductorByWallet(conductor2).conductorId;
    }

    function testDeploymentAndInitialState() public view override {
        // Test initial contract states (AppraisalsTest has 2 registered conductors)
        assertEq(accessControl.isAdmin(admin), true);
        assertEq(accessControl.isConductor(conductor1), true);
        assertEq(accessControl.isConductor(conductor2), true);
        assertEq(accessControl.isConductor(user1), false);

        assertEq(conductors.getConductorCount(), 2); // 2 conductors registered in setUp
        assertEq(designers.getDesignerCount(), 0);
        assertEq(appraisals.getNFTCount(), 0);
        assertEq(reactionPacks.get_packCount(), 0);

        assertEq(reactionPacks.defaultBasePrice(), BASE_PRICE);
        assertEq(reactionPacks.defaultPriceIncrement(), PRICE_INCREMENT);
    }

    function testSubmitNFT() public {
        vm.prank(conductor1);
        nftId = appraisals.submitNFT(
            1,
            address(ionicToken),
            IonicLibrary.TokenType.ERC721
        );

        assertEq(appraisals.getNFTCount(), 1);
        assertEq(nftId, 1);

        IonicLibrary.NFT memory nft = appraisals.getNFT(nftId);
        assertEq(nft.submitter, conductor1);
        assertEq(nft.nftContract, address(ionicToken));
        assertEq(nft.tokenId, 1);
        assertEq(nft.active, true);
        assertEq(nft.appraisalCount, 0);
    }

    function testCreateAppraisal() public {
        vm.prank(conductor1);
        nftId = appraisals.submitNFT(
            1,
            address(ionicToken),
            IonicLibrary.TokenType.ERC721
        );

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

        IonicLibrary.Appraisal memory appraisal = appraisals.getAppraisal(1);
        assertEq(appraisal.appraiser, conductor2);
        assertEq(appraisal.nftId, nftId);
        assertEq(appraisal.overallScore, 85);
        assertEq(appraisal.uri, "ipfs://appraisal");

        IonicLibrary.NFT memory nft = appraisals.getNFT(nftId);
        assertEq(nft.appraisalCount, 1);
        assertEq(nft.averageScore, 85);
    }

    function testRemoveNFT() public {
        vm.prank(conductor1);
        nftId = appraisals.submitNFT(
            1,
            address(ionicToken),
            IonicLibrary.TokenType.ERC721
        );

        IonicLibrary.NFT memory nft = appraisals.getNFT(nftId);
        assertEq(nft.active, true);

        vm.prank(conductor1);
        appraisals.removeNFT(nftId);

        nft = appraisals.getNFT(nftId);
        assertEq(nft.active, false);
    }

    function testMultipleAppraisals() public {
        vm.prank(conductor1);
        nftId = appraisals.submitNFT(
            1,
            address(ionicToken),
            IonicLibrary.TokenType.ERC721
        );

        vm.prank(conductor2);
        appraisals.createAppraisal(
            address(ionicToken),
            nftId,
            conductor2Id,
            80,
            "ipfs://appraisal1",
            new IonicLibrary.ReactionUsage[](0)
        );

        vm.prank(admin);
        ionicToken.mint(user1, 1);
        vm.prank(user1);
        conductors.registerProfile("ipfs://user1");
        uint256 user1Id = conductors.getConductorByWallet(user1).conductorId;

        vm.prank(user1);
        appraisals.createAppraisal(
            address(ionicToken),
            nftId,
            user1Id,
            90,
            "ipfs://appraisal2",
            new IonicLibrary.ReactionUsage[](0)
        );

        IonicLibrary.NFT memory nft = appraisals.getNFT(nftId);
        assertEq(nft.appraisalCount, 2);
        assertEq(nft.averageScore, 85); // (80 + 90) / 2
        assertEq(nft.totalScore, 170);
    }

    function testInvalidScore() public {
        vm.prank(conductor1);
        nftId = appraisals.submitNFT(
            1,
            address(ionicToken),
            IonicLibrary.TokenType.ERC721
        );

        vm.prank(conductor2);
        vm.expectRevert(IonicErrors.InvalidScore.selector);
        appraisals.createAppraisal(
            address(ionicToken),
            nftId,
            conductor2Id,
            101,
            "ipfs://invalid",
            new IonicLibrary.ReactionUsage[](0)
        );
    }
}
