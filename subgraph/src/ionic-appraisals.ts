import { ByteArray, Bytes, store } from "@graphprotocol/graph-ts";
import {
  AppraisalCreated as AppraisalCreatedEvent,
  IonicAppraisals,
  NFTRemoved as NFTRemovedEvent,
  NFTSubmitted as NFTSubmittedEvent,
} from "../generated/IonicAppraisals/IonicAppraisals";
import {
  Appraisal,
  Conductor,
  NFT,
  ReactionUsage,
  ConductorRegistry,
} from "../generated/schema";
import { Metadata as MetadataTemplate } from "../generated/templates";

export function handleAppraisalCreated(event: AppraisalCreatedEvent): void {
  let entity = new Appraisal(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.appraisalId))
  );
  let appraisals = IonicAppraisals.bind(event.address);
  let data = appraisals.getAppraisal(event.params.appraisalId);
  entity.appraiser = event.params.appraiser;
  entity.nftId = event.params.nftId;
  entity.nftContract = data.nftContract;
  entity.conductorId = event.params.conductorId;
  entity.appraisalId = event.params.appraisalId;

  entity.overallScore = event.params.overallScore;
  entity.conductor = Bytes.fromByteArray(
    Bytes.fromBigInt(event.params.conductorId)
  );

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.uri = data.uri;

  let ipfsHash = (entity.uri as string).split("/").pop();
  if (ipfsHash != null) {
    entity.metadata = ipfsHash;
    MetadataTemplate.create(ipfsHash);
  }

  let reactions: Bytes[] = [];
  for (let i = 0; i < data.reactions.length; i++) {
    let reaction = ReactionUsage.load(
      Bytes.fromUTF8(
        "count-" +
          data.reactions[i].count.toHexString() +
          "-reaction-" +
          data.reactions[i].reactionId.toHexString()
      )
    );

    if (!reaction) {
      reaction = new ReactionUsage(
        Bytes.fromUTF8(
          "count-" +
            data.reactions[i].count.toHexString() +
            "-reaction-" +
            data.reactions[i].reactionId.toHexString()
        )
      );
    }
    reaction.count = data.reactions[i].count;
    reaction.reaction = Bytes.fromByteArray(
      ByteArray.fromBigInt(data.reactions[i].reactionId)
    );
    reaction.save();
    reactions.push(reaction.id);
  }
  entity.reactions = reactions;

  let conductor = Conductor.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.conductorId))
  );

  if (conductor) {
    let apps: Bytes[] | null = conductor.appraisals;

    if (!apps) {
      apps = [];
    }
    apps.push(Bytes.fromByteArray(Bytes.fromBigInt(event.params.appraisalId)));
    conductor.appraisals = apps;

    let notAppraised = conductor.notAppraised;
    if (notAppraised) {
      let newNotAppraised: Bytes[] = [];
      let nftId = Bytes.fromByteArray(ByteArray.fromBigInt(event.params.nftId));

      for (let i = 0; i < notAppraised.length; i++) {
        if (!notAppraised[i].equals(nftId)) {
          newNotAppraised.push(notAppraised[i]);
        }
      }
      conductor.notAppraised = newNotAppraised;
    }

    conductor.save();
  }

  let nftEntity = NFT.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.nftId))
  );

  if (nftEntity) {
    let newAppraisals: Bytes[] | null = nftEntity.appraisals;

    if (!newAppraisals) {
      newAppraisals = [];
    }
    newAppraisals.push(
      Bytes.fromByteArray(Bytes.fromBigInt(event.params.appraisalId))
    );
    nftEntity.appraisals = newAppraisals;
    let data = appraisals.getNFT(event.params.nftId);

    nftEntity.averageScore = data.averageScore;
    nftEntity.appraisalCount = data.appraisalCount;
    nftEntity.totalScore = data.totalScore;
    nftEntity.save();

    entity.tokenType = nftEntity.tokenType;
  }

  entity.save();
}

export function handleNFTRemoved(event: NFTRemovedEvent): void {
  let entity = NFT.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.nftId))
  );

  if (entity) {
    let registry = ConductorRegistry.load("main");
    if (registry) {
      let conductorIds = registry.conductorIds;
      for (let i = 0; i < conductorIds.length; i++) {
        let conductor = Conductor.load(
          Bytes.fromByteArray(ByteArray.fromBigInt(conductorIds[i]))
        );

        if (conductor) {
          let newNotAppraised: Bytes[] = [];
          let nftId = entity.id;

          if (!conductor.notAppraised) {
            conductor.notAppraised = [];
          }

          for (let j = 0; j < (conductor.notAppraised as Bytes[]).length; j++) {
            if (!(conductor.notAppraised as Bytes[])[j].equals(nftId)) {
              newNotAppraised.push((conductor.notAppraised as Bytes[])[j]);
            }
          }
          conductor.notAppraised = newNotAppraised;
          conductor.save();
        }
      }
    }

    store.remove("NFT", entity.id.toHexString());
  }
}

export function handleNFTSubmitted(event: NFTSubmittedEvent): void {
  let entity = new NFT(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.nftId))
  );

  let appraisals = IonicAppraisals.bind(event.address);
  let data = appraisals.getNFT(event.params.nftId);
  entity.nftId = event.params.nftId;
  entity.nftContract = data.nftContract;
  entity.tokenId = event.params.tokenId;
  entity.submitter = event.params.submitter;
  entity.tokenType = event.params.tokenType;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.active = data.active;
  entity.appraisalCount = data.appraisalCount;
  entity.totalScore = data.totalScore;
  entity.averageScore = data.averageScore;

  entity.save();

  let registry = ConductorRegistry.load("main");
  if (registry) {
    let conductorIds = registry.conductorIds;
    for (let i = 0; i < conductorIds.length; i++) {
      let conductor = Conductor.load(
        Bytes.fromByteArray(ByteArray.fromBigInt(conductorIds[i]))
      );

      if (conductor) {
        let notAppraised = conductor.notAppraised;
        if (!notAppraised) {
          notAppraised = [];
        }
        notAppraised.push(entity.id);
        conductor.notAppraised = notAppraised;
        conductor.save();
      }
    }
  }
}
