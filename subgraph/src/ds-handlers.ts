import {
  Bytes,
  JSONValue,
  JSONValueKind,
  dataSource,
  json,
  log,
  BigInt,
} from "@graphprotocol/graph-ts";
import { Metadata, ResponseMetadata, BaseMetadata, ReactionMetadata } from "../generated/schema";

function extractString(
  value: JSONValue | null,
  fieldName: string
): string | null {
  if (!value || value.kind !== JSONValueKind.STRING) {
    return null;
  }
  let stringValue = value.toString();
  if (stringValue.includes("base64")) {
    log.warning("Skipping base64 encoded field: {}", [fieldName]);
    return null;
  }
  return stringValue;
}

export function handleMetadata(content: Bytes): void {
  let entityId = dataSource.stringParam();
  const obj = json.fromString(content.toString()).toObject();
  if (!obj) {
    log.error("Failed to parse JSON for Metadata: {}", [entityId]);
    return;
  }

  let metadata = new Metadata(entityId);

  let comment = extractString(obj.get("comment"), "comment");
  if (comment) metadata.comment = comment;

  let reactionsArray = obj.get("reactions");
  if (reactionsArray && reactionsArray.kind === JSONValueKind.ARRAY) {
    let reactions = reactionsArray.toArray();
    let reactionIds: string[] = [];

    for (let i = 0; i < reactions.length; i++) {
      let reactionObj = reactions[i].toObject();
      if (reactionObj) {
        let reactionId = entityId + "-reaction-" + i.toString();
        let reactionEntity = new ResponseMetadata(reactionId);

        let emoji = extractString(reactionObj.get("emoji"), "emoji");
        if (emoji) reactionEntity.emoji = emoji;

        let count = reactionObj.get("count");
        if (count && count.kind === JSONValueKind.NUMBER) {
          reactionEntity.count = BigInt.fromString(count.toBigInt().toString());
        } else if (count && count.kind === JSONValueKind.STRING) {
          reactionEntity.count = BigInt.fromString(count.toString());
        } else {
          reactionEntity.count = BigInt.fromI32(0);
        }

        reactionEntity.save();
        reactionIds.push(reactionId);
      }
    }
    metadata.reactions = reactionIds;
  }

  metadata.save();
}

export function handleBaseMetadata(content: Bytes): void {
  let entityId = dataSource.stringParam();
  const obj = json.fromString(content.toString()).toObject();
  if (!obj) {
    log.error("Failed to parse JSON for BaseMetadata: {}", [entityId]);
    return;
  }

  let metadata = new BaseMetadata(entityId);

  let title = extractString(obj.get("title"), "title");
  if (title) metadata.title = title;
  let description = extractString(obj.get("description"), "description");
  if (description) metadata.description = title;
  let image = extractString(obj.get("image"), "image");
  if (image) metadata.image = image;

  metadata.save();
}

export function handleReactionMetadata(content: Bytes): void {
  let entityId = dataSource.stringParam();
  const obj = json.fromString(content.toString()).toObject();
  if (!obj) {
    log.error("Failed to parse JSON for ReactionMetadata: {}", [entityId]);
    return;
  }

  let metadata = new ReactionMetadata(entityId);

  let title = extractString(obj.get("title"), "title");
  if (title) metadata.title = title;
  let description = extractString(obj.get("description"), "description");
  if (description) metadata.description = description;
  let image = extractString(obj.get("image"), "image");
  if (image) metadata.image = image;
  let model = extractString(obj.get("model"), "model");
  if (model) metadata.model = model;
  let workflow = extractString(obj.get("workflow"), "workflow");
  if (workflow) metadata.workflow = workflow;
  let prompt = extractString(obj.get("prompt"), "prompt");
  if (prompt) metadata.prompt = prompt;

  metadata.save();
}
