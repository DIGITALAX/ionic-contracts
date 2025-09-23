import { ByteArray, Bytes, store, BigInt } from "@graphprotocol/graph-ts";
import {
  ConductorDeleted as ConductorDeletedEvent,
  ConductorRegistered as ConductorRegisteredEvent,
  ConductorStatsUpdated as ConductorStatsUpdatedEvent,
  ConductorUpdated as ConductorUpdatedEvent,
  IonicConductors,
  ReviewSubmitted as ReviewSubmittedEvent,
  ReviewerURIUpdated as ReviewerURIUpdatedEvent,
} from "../generated/IonicConductors/IonicConductors";
import {
  Conductor,
  ReactionUsage,
  Reviewer,
  Review,
  ConductorRegistry,
} from "../generated/schema";
import {
  Metadata as MetadataTemplate,
  BaseMetadata as BaseMetadataTemplate,
} from "../generated/templates";

export function handleConductorDeleted(event: ConductorDeletedEvent): void {
  let entity = Conductor.load(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.conductorId))
  );

  if (entity) {
    store.remove("Conductor", entity.id.toHexString());
  }

  let registry = ConductorRegistry.load("main");
  if (registry) {
    let conductorIds = registry.conductorIds;
    let newIds: BigInt[] = [];
    for (let i = 0; i < conductorIds.length; i++) {
      if (!conductorIds[i].equals(event.params.conductorId)) {
        newIds.push(conductorIds[i]);
      }
    }
    registry.conductorIds = newIds;
    registry.save();
  }
}

export function handleConductorRegistered(
  event: ConductorRegisteredEvent
): void {
  let entity = new Conductor(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.conductorId))
  );
  entity.wallet = event.params.wallet;
  entity.conductorId = event.params.conductorId;
  entity.uri = event.params.uri;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let conductor = IonicConductors.bind(event.address);
  let data = conductor.getConductor(event.params.conductorId);
  entity.uri = event.params.uri;

  let ipfsHash = (entity.uri as string).split("/").pop();
  if (ipfsHash != null) {
    entity.metadata = ipfsHash;
    BaseMetadataTemplate.create(ipfsHash);
  }
  entity.appraisalCount = data.stats.appraisalCount;
  entity.totalScore = data.stats.totalScore;
  entity.averageScore = data.stats.averageScore;
  entity.reviewCount = data.stats.reviewCount;
  entity.totalReviewScore = data.stats.totalReviewScore;
  entity.averageReviewScore = data.stats.averageReviewScore;
  entity.inviteCount = data.stats.inviteCount;

  entity.save();

  let registry = ConductorRegistry.load("main");
  if (!registry) {
    registry = new ConductorRegistry("main");
    registry.conductorIds = [];
  }
  let conductorIds = registry.conductorIds;
  conductorIds.push(event.params.conductorId);
  registry.conductorIds = conductorIds;
  registry.save();
}

export function handleConductorStatsUpdated(
  event: ConductorStatsUpdatedEvent
): void {
  let entity = Conductor.load(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.conductorId))
  );

  if (entity) {
    let conductor = IonicConductors.bind(event.address);
    let data = conductor.getConductor(event.params.conductorId);

    entity.appraisalCount = data.stats.appraisalCount;
    entity.totalScore = data.stats.totalScore;
    entity.averageScore = data.stats.averageScore;

    entity.availableInvites = data.stats.availableInvites;

    entity.save();
  }
}

export function handleConductorUpdated(event: ConductorUpdatedEvent): void {
  let entity = Conductor.load(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.conductorId))
  );

  if (entity) {
    entity.uri = event.params.uri;

    let ipfsHash = (entity.uri as string).split("/").pop();
    if (ipfsHash != null) {
      entity.metadata = ipfsHash;
      BaseMetadataTemplate.create(ipfsHash);
    }
    entity.save();
  }
}

export function handleReviewSubmitted(event: ReviewSubmittedEvent): void {
  let entity = new Review(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.reviewId))
  );
  entity.reviewer = event.params.reviewer;
  entity.conductorId = event.params.conductorId;
  entity.reviewId = event.params.reviewId;
  entity.reviewScore = event.params.reviewScore;
  entity.timestamp = event.block.timestamp;
  entity.conductor = Bytes.fromByteArray(
    Bytes.fromBigInt(event.params.conductorId)
  );

  let conductor = IonicConductors.bind(event.address);
  let data = conductor.getReview(event.params.reviewId);
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

  entity.save();

  let reviewer = Reviewer.load(event.params.reviewer);

  if (!reviewer) {
    reviewer = new Reviewer(event.params.reviewer);
    reviewer.wallet = event.params.reviewer;
  }

  let reviews: Bytes[] | null = reviewer.reviews;

  if (!reviews) {
    reviews = [];
  }
  let reviewData = conductor.getReviewer(event.params.reviewer);

  reviews.push(entity.id);
  reviewer.reviews = reviews;
  reviewer.reviewCount = reviewData.stats.reviewCount;
  reviewer.totalScore = reviewData.stats.totalScore;
  reviewer.averageScore = reviewData.stats.averageScore;
  reviewer.lastReviewTimestamp = reviewData.stats.lastReviewTimestamp;

  reviewer.save();

  let conductorEntity = Conductor.load(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.conductorId))
  );

  if (conductorEntity) {
    let reviews: Bytes[] | null = conductorEntity.reviews;

    if (!reviews) {
      reviews = [];
    }
    reviews.push(entity.id);

    let data = conductor.getConductor(event.params.conductorId);

    conductorEntity.averageReviewScore = data.stats.averageReviewScore;
    conductorEntity.totalReviewScore = data.stats.totalReviewScore;
    conductorEntity.reviews = reviews;

    conductorEntity.save();
  }
}

export function handleReviewerURIUpdated(event: ReviewerURIUpdatedEvent): void {
  let entity = Reviewer.load(event.params.reviewer);

  if (!entity) {
    entity = new Reviewer(event.params.reviewer);
    entity.wallet = event.params.reviewer;
  }
  entity.uri = event.params.uri;

  let ipfsHash = (entity.uri as string).split("/").pop();
  if (ipfsHash != null) {
    entity.metadata = ipfsHash;
    BaseMetadataTemplate.create(ipfsHash);
  }

  entity.save();
}
