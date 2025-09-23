import { BigInt, ByteArray, Bytes } from "@graphprotocol/graph-ts";
import {
  IonicReactionPacks,
  PackPurchased as PackPurchasedEvent,
  ReactionAdded as ReactionAddedEvent,
  ReactionPackCreated as ReactionPackCreatedEvent,
} from "../generated/IonicReactionPacks/IonicReactionPacks";
import {
  Reaction,
  ReactionPack,
  Purchase,
  Designer,
  TokenReaction,
} from "../generated/schema";
import { IonicDesigners } from "../generated/IonicDesigners/IonicDesigners";
import {
  BaseMetadata as BaseMetadataTemplate,
  ReactionMetadata as ReactionMetadataTemplate,
} from "../generated/templates";

export function handlePackPurchased(event: PackPurchasedEvent): void {
  let entity = new Purchase(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.purchaseId))
  );
  let pack = IonicReactionPacks.bind(event.address);
  let purchase = pack.getPurchase(event.params.packId);
  entity.buyer = event.params.buyer;
  entity.packId = event.params.packId;
  entity.price = event.params.price;
  entity.purchaseId = event.params.purchaseId;
  entity.editionNumber = event.params.editionNumber;
  entity.shareWeight = purchase.shareWeight;
  entity.pack = Bytes.fromByteArray(Bytes.fromBigInt(event.params.packId));

  entity.timestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityPack = ReactionPack.load(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.packId))
  );

  if (entityPack) {
    let data = pack.getReactionPack(event.params.packId);
    entityPack.soldCount = data.soldCount;

    let packPurchases = pack.getPackPurchases(event.params.packId);
    let purchases: Bytes[] = [];

    for (let i = 0; i < packPurchases.length; i++) {
      purchases.push(Bytes.fromByteArray(Bytes.fromBigInt(packPurchases[i])));
    }

    purchases.push(
      Bytes.fromByteArray(Bytes.fromBigInt(event.params.purchaseId))
    );
    entityPack.purchases = purchases;
    entityPack.save();

    let reactions = entityPack.reactions;

    for (let i = 0; i < reactions.length; i++) {
      let reaction = Reaction.load(reactions[i]);
      if (reaction) {
        let tokenIds: BigInt[] = [];
        let reactionData = pack.getReaction(reaction.reactionId);

        for (let j = 0; j < reactionData.tokenIds.length; j++) {
          let tokenReaction = new TokenReaction(
            Bytes.fromByteArray(ByteArray.fromBigInt(reactionData.tokenIds[j]))
          );
          tokenReaction.tokenId = reactionData.tokenIds[j];
          tokenReaction.reaction = reaction.id;
          tokenReaction.save();
          tokenIds.push(reactionData.tokenIds[j]);
        }

        reaction.tokenIds = tokenIds;
        reaction.save();
      }
    }
  }
}

export function handleReactionAdded(event: ReactionAddedEvent): void {
  let entity = new Reaction(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.reactionId))
  );
  entity.packId = event.params.packId;
  entity.reactionId = event.params.reactionId;
  entity.reactionUri = event.params.reactionUri;
  let ipfsHash = (entity.reactionUri as string).split("/").pop();

  if (ipfsHash != null) {
    entity.reactionMetadata = ipfsHash;
    ReactionMetadataTemplate.create(ipfsHash);
  }

  entity.pack = Bytes.fromByteArray(Bytes.fromBigInt(event.params.packId));

  entity.save();
}

export function handleReactionPackCreated(
  event: ReactionPackCreatedEvent
): void {
  let entity = new ReactionPack(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.packId))
  );
  let reaction = IonicReactionPacks.bind(event.address);
  let data = reaction.getReactionPack(event.params.packId);
  let designer = IonicDesigners.bind(reaction.designers());
  let designerId = designer.getDesignerByWallet(
    event.params.designer
  ).designerId;

  entity.designer = event.params.designer;
  entity.designerProfile = Bytes.fromByteArray(
    Bytes.fromBigInt(designerId)
  );

  entity.packId = event.params.packId;
  entity.basePrice = event.params.basePrice;
  entity.maxEditions = event.params.maxEditions;
  entity.conductorReservedSpots = event.params.conductorReservedSpots;

  entity.currentPrice = data.currentPrice;
  entity.maxEditions = data.maxEditions;
  entity.soldCount = data.soldCount;
  entity.conductorReservedSpots = data.conductorReservedSpots;
  entity.priceIncrement = reaction.defaultPriceIncrement();

  entity.active = data.active;
  entity.packUri = data.packUri;

  let ipfsHash = (entity.packUri as string).split("/").pop();
  if (ipfsHash != null) {
    entity.packMetadata = ipfsHash;
    BaseMetadataTemplate.create(ipfsHash);
  }

  let reactions: Bytes[] = [];

  for (let i = 0; i < data.reactionIds.length; i++) {
    reactions.push(Bytes.fromByteArray(Bytes.fromBigInt(data.reactionIds[i])));
  }

  entity.reactions = reactions;

  entity.save();

  let designerEntity = Designer.load(
    Bytes.fromByteArray(Bytes.fromBigInt(designerId))
  );

  if (designerEntity) {
    let packs: Bytes[] | null = designerEntity.reactionPacks;

    if (!packs) {
      packs = [];
    }
    packs.push(Bytes.fromByteArray(Bytes.fromBigInt(event.params.packId)));
    designerEntity.reactionPacks = packs;
    designerEntity.save();
  }
}
