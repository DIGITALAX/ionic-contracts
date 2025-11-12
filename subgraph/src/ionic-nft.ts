import {
  Approval as ApprovalEvent,
  ApprovalForAll as ApprovalForAllEvent,
  MintersAuthorized as MintersAuthorizedEvent,
  TokenMinted as TokenMintedEvent,
  TokenURIUpdated as TokenURIUpdatedEvent,
  Transfer as TransferEvent,
} from "../generated/IonicNFT/IonicNFT";
import {
  Approval,
  ApprovalForAll,
  MintersAuthorized,
  TokenMinted,
  TokenURIUpdated,
  Transfer,
} from "../generated/schema";
import { Bytes } from "@graphprotocol/graph-ts";

export function handleApproval(event: ApprovalEvent): void {
  let entity = new Approval(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.owner = event.params.owner;
  entity.approved = event.params.approved;
  entity.tokenId = event.params.tokenId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleApprovalForAll(event: ApprovalForAllEvent): void {
  let entity = new ApprovalForAll(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.owner = event.params.owner;
  entity.operator = event.params.operator;
  entity.approved = event.params.approved;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleMintersAuthorized(event: MintersAuthorizedEvent): void {
  let entity = new MintersAuthorized(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.minters = changetype<Bytes[]>(event.params.minters);

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleTokenMinted(event: TokenMintedEvent): void {
  let entity = new TokenMinted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.minter = event.params.minter;
  entity.tokenId = event.params.tokenId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleTokenURIUpdated(event: TokenURIUpdatedEvent): void {
  let entity = new TokenURIUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.reason = event.params.reason;
  entity.uri = event.params.uri;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleTransfer(event: TransferEvent): void {
  let entity = new Transfer(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.from = event.params.from;
  entity.to = event.params.to;
  entity.tokenId = event.params.tokenId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
