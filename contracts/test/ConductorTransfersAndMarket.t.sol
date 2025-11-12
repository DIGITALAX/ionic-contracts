// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;

import "./Setup.t.sol";

contract ConductorTransfersAndMarketTest is SetupTest {

  function testConductorNFTTransferNewOwnerCanUpdateProfile() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1-v1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    IonicLibrary.Conductor memory conductorBefore = conductors.getConductor(c1Id);
    assertEq(conductorBefore.uri, "ipfs://conductor1-v1");

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    vm.prank(user1);
    conductors.updateProfile(1, "ipfs://conductor1-v2-by-user1");

    IonicLibrary.Conductor memory conductorAfter = conductors.getConductor(c1Id);
    assertEq(conductorAfter.uri, "ipfs://conductor1-v2-by-user1");
  }

  function testOldOwnerCannotUpdateProfileAfterTransfer() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    vm.prank(conductor1);
    vm.expectRevert(IonicErrors.Unauthorized.selector);
    conductors.updateProfile(1, "ipfs://conductor1-attempt");
  }

  function testNewOwnerCanCreateAppraisalAsTransferredConductor() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");

    vm.prank(conductor1);
    uint256 nftId = appraisals.submitNFT(1, address(ionicToken), IonicLibrary.TokenType.ERC721);

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    vm.prank(user1);
    appraisals.createAppraisal(
      address(ionicToken),
      nftId,
      1,
      75,
      "ipfs://appraisal-by-user1",
      new IonicLibrary.ReactionUsage[](0)
    );

    assertEq(appraisals.getAppraisalCount(), 1);
    IonicLibrary.Appraisal memory appraisal = appraisals.getAppraisal(1);
    assertEq(appraisal.appraiser, user1);
  }

  function testNewOwnerCanInviteDesignersAfterTransfer() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    vm.prank(user1);
    designers.inviteDesigner(c1Id, designer1);

    assertEq(designers.isDesigner(designer1), true);

    IonicLibrary.Designer memory designer = designers.getDesignerByWallet(designer1);
    assertEq(designer.invitedBy, user1);
  }

  function testConductorStatsInheritedAfterTransfer() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    IonicLibrary.Conductor memory conductorBefore = conductors.getConductor(c1Id);
    assertEq(conductorBefore.stats.appraisalCount, 0);

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    IonicLibrary.Conductor memory conductorAfter = conductors.getConductor(c1Id);
    assertEq(conductorAfter.stats.appraisalCount, 0);
  }

  function testPreviousDesignersRemainInvitedAfterTransfer() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    assertEq(designers.isDesigner(designer1), true);

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    assertEq(designers.isDesigner(designer1), true);
    IonicLibrary.Designer memory designer = designers.getDesignerByWallet(designer1);
    assertEq(designer.invitedBy, conductor1);
  }

  function testNewOwnerCanUseRemainingInvites() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    vm.prank(user1);
    designers.inviteDesigner(c1Id, designer1);

    assertEq(designers.isDesigner(designer1), true);
  }

  function testReservedPeriodEnforcedForConductorsOnly() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    string[] memory reactionUris = new string[](1);
    reactionUris[0] = "ipfs://reaction1";

    vm.prank(designer1);
    uint256 packId = reactionPacks.createReactionPack(5, 3, "ipfs://pack", reactionUris);

    IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
    uint256 currentPrice = pack.currentPrice;

    vm.prank(conductor1);
    monaToken.approve(address(reactionPacks), currentPrice);
    vm.prank(conductor1);
    reactionPacks.purchaseReactionPack(packId);

    vm.prank(conductor2);
    conductors.updateProfile(2, "ipfs://conductor2");
    vm.prank(conductor2);
    monaToken.approve(address(reactionPacks), currentPrice + PRICE_INCREMENT);
    vm.prank(conductor2);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);
    assertEq(pack.soldCount, 2);

    vm.prank(user1);
    monaToken.approve(address(reactionPacks), currentPrice + (2 * PRICE_INCREMENT));
    vm.prank(user1);
    vm.expectRevert(IonicErrors.ConductorSpotsOnly.selector);
    reactionPacks.purchaseReactionPack(packId);
  }

  function testNonConductorCanBuyAfterReservedPeriod() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    string[] memory reactionUris = new string[](1);
    reactionUris[0] = "ipfs://reaction1";

    vm.prank(designer1);
    uint256 packId = reactionPacks.createReactionPack(5, 2, "ipfs://pack", reactionUris);

    IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);

    vm.prank(conductor1);
    monaToken.approve(address(reactionPacks), pack.currentPrice);
    vm.prank(conductor1);
    reactionPacks.purchaseReactionPack(packId);

    vm.prank(conductor2);
    conductors.updateProfile(2, "ipfs://conductor2");
    vm.prank(conductor2);
    monaToken.approve(address(reactionPacks), pack.currentPrice + PRICE_INCREMENT);
    vm.prank(conductor2);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);

    vm.prank(user1);
    monaToken.approve(address(reactionPacks), pack.currentPrice + (2 * PRICE_INCREMENT));
    vm.prank(user1);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);
    assertEq(pack.soldCount, 3);
  }

  function testProfitDistributionToFirstBuyer() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    string[] memory reactionUris = new string[](1);
    reactionUris[0] = "ipfs://reaction1";

    vm.prank(designer1);
    uint256 packId = reactionPacks.createReactionPack(10, 3, "ipfs://pack", reactionUris);

    IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
    uint256 firstPrice = pack.currentPrice;

    uint256 conductor1BalanceBefore = monaToken.balanceOf(conductor1);

    vm.prank(conductor1);
    monaToken.approve(address(reactionPacks), firstPrice);
    vm.prank(conductor1);
    reactionPacks.purchaseReactionPack(packId);

    uint256 conductor2Price = firstPrice + PRICE_INCREMENT;
    vm.prank(conductor2);
    conductors.updateProfile(2, "ipfs://conductor2");
    vm.prank(conductor2);
    monaToken.approve(address(reactionPacks), conductor2Price);
    vm.prank(conductor2);
    reactionPacks.purchaseReactionPack(packId);

    uint256 conductor1BalanceAfter = monaToken.balanceOf(conductor1);

    uint256 buyerSharePool = (conductor2Price * 10) / 100;

    uint256 expectedBalanceAfter = conductor1BalanceBefore - firstPrice + buyerSharePool;
    assertEq(conductor1BalanceAfter, expectedBalanceAfter);
  }

  function testProfitDistributionMultipleBuyers() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    string[] memory reactionUris = new string[](1);
    reactionUris[0] = "ipfs://reaction1";

    vm.prank(designer1);
    uint256 packId = reactionPacks.createReactionPack(10, 2, "ipfs://pack", reactionUris);

    IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
    uint256 price1 = pack.currentPrice;

    uint256 designerBalanceBefore = monaToken.balanceOf(designer1);
    uint256 conductor1BalanceBefore = monaToken.balanceOf(conductor1);

    vm.prank(conductor1);
    monaToken.approve(address(reactionPacks), price1);
    vm.prank(conductor1);
    reactionPacks.purchaseReactionPack(packId);

    uint256 price2 = price1 + PRICE_INCREMENT;
    vm.prank(conductor2);
    conductors.updateProfile(2, "ipfs://conductor2");
    vm.prank(conductor2);
    monaToken.approve(address(reactionPacks), price2);
    vm.prank(conductor2);
    reactionPacks.purchaseReactionPack(packId);

    uint256 designerBalanceAfter = monaToken.balanceOf(designer1);
    uint256 conductor1BalanceAfter = monaToken.balanceOf(conductor1);

    uint256 designerEarned1 = price1;
    uint256 designerEarned2 = (price2 * 90) / 100;
    uint256 totalDesignerEarned = designerEarned1 + designerEarned2;

    uint256 buyerSharePool = (price2 * 10) / 100;

    uint256 expectedConductor1Balance = conductor1BalanceBefore - price1 + buyerSharePool;
    assertEq(designerBalanceAfter - designerBalanceBefore, totalDesignerEarned);
    assertEq(conductor1BalanceAfter, expectedConductor1Balance);
  }

  function testEditionLimitRespected() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    string[] memory reactionUris = new string[](1);
    reactionUris[0] = "ipfs://reaction1";

    vm.prank(designer1);
    uint256 packId = reactionPacks.createReactionPack(2, 1, "ipfs://pack", reactionUris);

    IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);

    vm.prank(conductor1);
    monaToken.approve(address(reactionPacks), pack.currentPrice);
    vm.prank(conductor1);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);
    vm.prank(conductor2);
    conductors.updateProfile(2, "ipfs://conductor2");
    vm.prank(conductor2);
    monaToken.approve(address(reactionPacks), pack.currentPrice);
    vm.prank(conductor2);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);
    assertEq(pack.soldCount, 2);

    vm.prank(user1);
    monaToken.approve(address(reactionPacks), pack.currentPrice);
    vm.prank(user1);
    vm.expectRevert(IonicErrors.SoldOut.selector);
    reactionPacks.purchaseReactionPack(packId);
  }

  function testConductorTransferMaintainsProfitEarning() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    string[] memory reactionUris = new string[](1);
    reactionUris[0] = "ipfs://reaction1";

    vm.prank(designer1);
    uint256 packId = reactionPacks.createReactionPack(10, 2, "ipfs://pack", reactionUris);

    IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);
    uint256 price1 = pack.currentPrice;

    vm.prank(conductor1);
    monaToken.approve(address(reactionPacks), price1);
    vm.prank(conductor1);
    reactionPacks.purchaseReactionPack(packId);

    uint256 conductor1BalanceBefore = monaToken.balanceOf(conductor1);

    vm.prank(conductor1);
    ionicToken.transferFrom(conductor1, user1, 1);

    pack = reactionPacks.getReactionPack(packId);
    uint256 price2 = pack.currentPrice;

    vm.prank(conductor2);
    conductors.updateProfile(2, "ipfs://conductor2");
    vm.prank(conductor2);
    monaToken.approve(address(reactionPacks), price2);
    vm.prank(conductor2);
    reactionPacks.purchaseReactionPack(packId);

    uint256 conductor1BalanceAfter = monaToken.balanceOf(conductor1);

    uint256 expectedProfit = (price2 * 10) / 100;

    assertEq(conductor1BalanceAfter - conductor1BalanceBefore, expectedProfit);
  }

  function testComplexMultiBuyerScenario() public {
    vm.prank(conductor1);
    conductors.updateProfile(1, "ipfs://conductor1");
    uint256 c1Id = conductors.getConductorId(conductor1);

    vm.prank(conductor1);
    designers.inviteDesigner(c1Id, designer1);

    string[] memory reactionUris = new string[](1);
    reactionUris[0] = "ipfs://reaction1";

    vm.prank(designer1);
    uint256 packId = reactionPacks.createReactionPack(10, 2, "ipfs://pack", reactionUris);

    IonicLibrary.ReactionPack memory pack = reactionPacks.getReactionPack(packId);

    uint256[] memory prices = new uint256[](4);

    uint256 designerBalanceBefore = monaToken.balanceOf(designer1);

    prices[0] = pack.currentPrice;
    vm.prank(conductor1);
    monaToken.approve(address(reactionPacks), prices[0]);
    vm.prank(conductor1);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);
    prices[1] = pack.currentPrice;
    vm.prank(conductor2);
    conductors.updateProfile(2, "ipfs://conductor2");
    vm.prank(conductor2);
    monaToken.approve(address(reactionPacks), prices[1]);
    vm.prank(conductor2);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);
    prices[2] = pack.currentPrice;
    vm.prank(user1);
    monaToken.approve(address(reactionPacks), prices[2]);
    vm.prank(user1);
    reactionPacks.purchaseReactionPack(packId);

    pack = reactionPacks.getReactionPack(packId);
    prices[3] = pack.currentPrice;
    vm.prank(user2);
    monaToken.approve(address(reactionPacks), prices[3]);
    vm.prank(user2);
    reactionPacks.purchaseReactionPack(packId);

    uint256 designerBalanceAfter = monaToken.balanceOf(designer1);

    uint256 designerTotal = prices[0];
    for (uint256 i = 1; i < 4; i++) {
      designerTotal += (prices[i] * 90) / 100;
    }

    uint256 designerDifference = designerBalanceAfter - designerBalanceBefore;

    assertEq(designerDifference, designerTotal);
  }
}