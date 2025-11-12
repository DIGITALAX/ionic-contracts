// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract ReactionPacksTest is SetupTest {

    function testInitialReactionPackState() public view {
        assertEq(reactionPacks.getPackCount(), 0);
        assertEq(reactionPacks.defaultBasePrice(), BASE_PRICE);
        assertEq(reactionPacks.defaultPriceIncrement(), PRICE_INCREMENT);
    }

    function testCreateReactionPack() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        string[] memory reactionUris = new string[](3);
        reactionUris[0] = "ipfs://reaction1";
        reactionUris[1] = "ipfs://reaction2";
        reactionUris[2] = "ipfs://reaction3";

        vm.prank(user1);
        uint256 packId = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack1",
            reactionUris
        );

        assertEq(reactionPacks.getPackCount(), 1);
        assertEq(packId, 1);

        IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
        assertEq(pack.designer, user1);
        assertEq(pack.packUri, "ipfs://pack1");
        assertEq(pack.maxEditions, 10);
        assertEq(pack.soldCount, 0);
        assertEq(pack.conductorReservedSpots, 2);
        assertEq(pack.active, true);
    }

    function testOnlyDesignersCanCreatePacks() public {
        string[] memory reactionUris = new string[](1);
        reactionUris[0] = "ipfs://reaction1";

        vm.prank(user1);
        vm.expectRevert(IonicErrors.DesignerNotFound.selector);
        reactionPacks.createReactionPack(10, 2, "ipfs://pack1", reactionUris);
    }

    function testPurchaseReactionPack() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        string[] memory reactionUris = new string[](3);
        reactionUris[0] = "ipfs://reaction1";
        reactionUris[1] = "ipfs://reaction2";
        reactionUris[2] = "ipfs://reaction3";

        vm.prank(user1);
        uint256 packId = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack1",
            reactionUris
        );

        IonicLibrary.ReactionPack memory packData = reactionPacks.getReactionPack(packId);
        uint256 currentPrice = packData.currentPrice;

        vm.prank(conductor1);
        monaToken.approve(address(reactionPacks), currentPrice);

        uint256 balanceBefore = reactionPacks.balanceOf(conductor1);
        vm.prank(conductor1);
        reactionPacks.purchaseReactionPack(packId);

        uint256 balanceAfter = reactionPacks.balanceOf(conductor1);
        assertEq(balanceAfter, balanceBefore + reactionUris.length);

        IonicLibrary.ReactionPack memory packAfter = reactionPacks.getReactionPack(packId);
        assertEq(packAfter.soldCount, 1);
    }

    function testProgressivePricing() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        string[] memory reactionUris = new string[](3);
        reactionUris[0] = "ipfs://reaction1";
        reactionUris[1] = "ipfs://reaction2";
        reactionUris[2] = "ipfs://reaction3";

        vm.prank(user1);
        uint256 packId = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack1",
            reactionUris
        );

        IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
        uint256 firstPrice = pack.currentPrice;
        assertEq(firstPrice, BASE_PRICE);

        vm.prank(conductor1);
        monaToken.approve(address(reactionPacks), firstPrice);
        vm.prank(conductor1);
        reactionPacks.purchaseReactionPack(packId);

        pack = reactionPacks.getReactionPack(packId);
        uint256 secondPrice = pack.currentPrice;
        assertEq(secondPrice, BASE_PRICE + PRICE_INCREMENT);

        vm.prank(conductor2);
        monaToken.approve(address(reactionPacks), secondPrice);
        vm.prank(conductor2);
        reactionPacks.purchaseReactionPack(packId);

        pack = reactionPacks.getReactionPack(packId);
        uint256 thirdPrice = pack.currentPrice;
        assertEq(thirdPrice, BASE_PRICE + (2 * PRICE_INCREMENT));
    }

    function testSoldOutReactionPack() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        string[] memory reactionUris = new string[](1);
        reactionUris[0] = "ipfs://reaction1";

        vm.prank(user1);
        uint256 packId = reactionPacks.createReactionPack(
            1,
            1,
            "ipfs://pack1",
            reactionUris
        );

        IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
        uint256 price = pack.currentPrice;

        vm.prank(conductor1);
        monaToken.approve(address(reactionPacks), price);
        vm.prank(conductor1);
        reactionPacks.purchaseReactionPack(packId);

        pack = reactionPacks.getReactionPack(packId);
        uint256 nextPrice = pack.currentPrice;

        vm.prank(conductor2);
        monaToken.approve(address(reactionPacks), nextPrice);
        vm.prank(conductor2);
        vm.expectRevert(IonicErrors.SoldOut.selector);
        reactionPacks.purchaseReactionPack(packId);
    }

    function testOnlyConductorsCanPurchase() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        string[] memory reactionUris = new string[](1);
        reactionUris[0] = "ipfs://reaction1";

        vm.prank(user1);
        uint256 packId = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack1",
            reactionUris
        );

        IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
        uint256 price = pack.currentPrice;

        vm.prank(user2);
        monaToken.approve(address(reactionPacks), price);
        vm.prank(user2);
        vm.expectRevert(IonicErrors.ConductorSpotsOnly.selector);
        reactionPacks.purchaseReactionPack(packId);
    }

    function testGetPurchasesByPack() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        string[] memory reactionUris = new string[](1);
        reactionUris[0] = "ipfs://reaction1";

        vm.prank(user1);
        uint256 packId = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack1",
            reactionUris
        );

        IonicLibrary.ReactionPack memory packData = reactionPacks.getReactionPack(packId);
        uint256 price1 = packData.currentPrice;
        vm.prank(conductor1);
        monaToken.approve(address(reactionPacks), price1);
        vm.prank(conductor1);
        reactionPacks.purchaseReactionPack(packId);

        packData = reactionPacks.getReactionPack(packId);
        uint256 price2 = packData.currentPrice;
        vm.prank(conductor2);
        monaToken.approve(address(reactionPacks), price2);
        vm.prank(conductor2);
        reactionPacks.purchaseReactionPack(packId);

        uint256[] memory purchaseTokenIds = reactionPacks.getPackPurchases(packId);
        assertEq(purchaseTokenIds.length, 2);
    }

    function testGetPurchasesByBuyer() public {
        vm.prank(conductor1);
        conductors.updateProfile(1, "ipfs://conductor1");
        uint256 c1Id = conductors.getConductorId(conductor1);

        vm.prank(conductor1);
        designers.inviteDesigner(c1Id, user1);

        string[] memory reactionUris = new string[](1);
        reactionUris[0] = "ipfs://reaction1";

        vm.prank(user1);
        uint256 packId1 = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack1",
            reactionUris
        );

        vm.prank(user1);
        uint256 packId2 = reactionPacks.createReactionPack(
            10,
            2,
            "ipfs://pack2",
            reactionUris
        );

        IonicLibrary.ReactionPack memory pack1Data = reactionPacks.getReactionPack(packId1);
        IonicLibrary.ReactionPack memory pack2Data = reactionPacks.getReactionPack(packId2);
        uint256 price1 = pack1Data.currentPrice;
        uint256 price2 = pack2Data.currentPrice;

        vm.prank(conductor1);
        monaToken.approve(address(reactionPacks), price1 + price2);
        vm.prank(conductor1);
        reactionPacks.purchaseReactionPack(packId1);
        vm.prank(conductor1);
        reactionPacks.purchaseReactionPack(packId2);

        uint256[] memory buyerTokenIds = reactionPacks.getBuyerPurchases(conductor1);
        assertEq(buyerTokenIds.length, 2);
    }
}