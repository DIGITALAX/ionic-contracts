import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  AppraisalCreated,
  NFTRemoved,
  NFTSubmitted
} from "../generated/IonicAppraisals/IonicAppraisals"

export function createAppraisalCreatedEvent(
  appraiser: Address,
  nftId: BigInt,
  conductorId: BigInt,
  appraisalId: BigInt,
  overallScore: BigInt
): AppraisalCreated {
  let appraisalCreatedEvent = changetype<AppraisalCreated>(newMockEvent())

  appraisalCreatedEvent.parameters = new Array()

  appraisalCreatedEvent.parameters.push(
    new ethereum.EventParam("appraiser", ethereum.Value.fromAddress(appraiser))
  )
  appraisalCreatedEvent.parameters.push(
    new ethereum.EventParam("nftId", ethereum.Value.fromUnsignedBigInt(nftId))
  )
  appraisalCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "conductorId",
      ethereum.Value.fromUnsignedBigInt(conductorId)
    )
  )
  appraisalCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "appraisalId",
      ethereum.Value.fromUnsignedBigInt(appraisalId)
    )
  )
  appraisalCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "overallScore",
      ethereum.Value.fromUnsignedBigInt(overallScore)
    )
  )

  return appraisalCreatedEvent
}

export function createNFTRemovedEvent(
  nftId: BigInt,
  submitter: Address
): NFTRemoved {
  let nftRemovedEvent = changetype<NFTRemoved>(newMockEvent())

  nftRemovedEvent.parameters = new Array()

  nftRemovedEvent.parameters.push(
    new ethereum.EventParam("nftId", ethereum.Value.fromUnsignedBigInt(nftId))
  )
  nftRemovedEvent.parameters.push(
    new ethereum.EventParam("submitter", ethereum.Value.fromAddress(submitter))
  )

  return nftRemovedEvent
}

export function createNFTSubmittedEvent(
  nftId: BigInt,
  contractAddress: Address,
  tokenId: BigInt,
  submitter: Address,
  tokenType: i32
): NFTSubmitted {
  let nftSubmittedEvent = changetype<NFTSubmitted>(newMockEvent())

  nftSubmittedEvent.parameters = new Array()

  nftSubmittedEvent.parameters.push(
    new ethereum.EventParam("nftId", ethereum.Value.fromUnsignedBigInt(nftId))
  )
  nftSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "contractAddress",
      ethereum.Value.fromAddress(contractAddress)
    )
  )
  nftSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  nftSubmittedEvent.parameters.push(
    new ethereum.EventParam("submitter", ethereum.Value.fromAddress(submitter))
  )
  nftSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenType",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(tokenType))
    )
  )

  return nftSubmittedEvent
}
