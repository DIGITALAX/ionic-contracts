import { newMockEvent } from "matchstick-as"
import { ethereum, BigInt, Address } from "@graphprotocol/graph-ts"
import {
  ConductorDeleted,
  ConductorRegistered,
  ConductorStatsUpdated,
  ConductorUpdated,
  ReviewSubmitted
} from "../generated/IonicConductors/IonicConductors"

export function createConductorDeletedEvent(
  conductorId: BigInt,
  wallet: Address
): ConductorDeleted {
  let conductorDeletedEvent = changetype<ConductorDeleted>(newMockEvent())

  conductorDeletedEvent.parameters = new Array()

  conductorDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "conductorId",
      ethereum.Value.fromUnsignedBigInt(conductorId)
    )
  )
  conductorDeletedEvent.parameters.push(
    new ethereum.EventParam("wallet", ethereum.Value.fromAddress(wallet))
  )

  return conductorDeletedEvent
}

export function createConductorRegisteredEvent(
  wallet: Address,
  conductorId: BigInt,
  uri: string
): ConductorRegistered {
  let conductorRegisteredEvent = changetype<ConductorRegistered>(newMockEvent())

  conductorRegisteredEvent.parameters = new Array()

  conductorRegisteredEvent.parameters.push(
    new ethereum.EventParam("wallet", ethereum.Value.fromAddress(wallet))
  )
  conductorRegisteredEvent.parameters.push(
    new ethereum.EventParam(
      "conductorId",
      ethereum.Value.fromUnsignedBigInt(conductorId)
    )
  )
  conductorRegisteredEvent.parameters.push(
    new ethereum.EventParam("uri", ethereum.Value.fromString(uri))
  )

  return conductorRegisteredEvent
}

export function createConductorStatsUpdatedEvent(
  conductorId: BigInt,
  appraisalCount: BigInt,
  averageScore: BigInt
): ConductorStatsUpdated {
  let conductorStatsUpdatedEvent =
    changetype<ConductorStatsUpdated>(newMockEvent())

  conductorStatsUpdatedEvent.parameters = new Array()

  conductorStatsUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "conductorId",
      ethereum.Value.fromUnsignedBigInt(conductorId)
    )
  )
  conductorStatsUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "appraisalCount",
      ethereum.Value.fromUnsignedBigInt(appraisalCount)
    )
  )
  conductorStatsUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "averageScore",
      ethereum.Value.fromUnsignedBigInt(averageScore)
    )
  )

  return conductorStatsUpdatedEvent
}

export function createConductorUpdatedEvent(
  conductorId: BigInt,
  uri: string
): ConductorUpdated {
  let conductorUpdatedEvent = changetype<ConductorUpdated>(newMockEvent())

  conductorUpdatedEvent.parameters = new Array()

  conductorUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "conductorId",
      ethereum.Value.fromUnsignedBigInt(conductorId)
    )
  )
  conductorUpdatedEvent.parameters.push(
    new ethereum.EventParam("uri", ethereum.Value.fromString(uri))
  )

  return conductorUpdatedEvent
}

export function createReviewSubmittedEvent(
  reviewer: Address,
  conductorId: BigInt,
  reviewId: BigInt,
  reviewScore: BigInt
): ReviewSubmitted {
  let reviewSubmittedEvent = changetype<ReviewSubmitted>(newMockEvent())

  reviewSubmittedEvent.parameters = new Array()

  reviewSubmittedEvent.parameters.push(
    new ethereum.EventParam("reviewer", ethereum.Value.fromAddress(reviewer))
  )
  reviewSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "conductorId",
      ethereum.Value.fromUnsignedBigInt(conductorId)
    )
  )
  reviewSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "reviewId",
      ethereum.Value.fromUnsignedBigInt(reviewId)
    )
  )
  reviewSubmittedEvent.parameters.push(
    new ethereum.EventParam(
      "reviewScore",
      ethereum.Value.fromUnsignedBigInt(reviewScore)
    )
  )

  return reviewSubmittedEvent
}
