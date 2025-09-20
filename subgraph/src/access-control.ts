import {
  AdminAdded as AdminAddedEvent,
  AdminRemoved as AdminRemovedEvent,
  AdminRevoked as AdminRevokedEvent,
  MonaTokenUpdated as MonaTokenUpdatedEvent,
  PodeTokenUpdated as PodeTokenUpdatedEvent
} from "../generated/AccessControl/AccessControl"
import {
  AdminAdded,
  AdminRemoved,
  AdminRevoked,
  MonaTokenUpdated,
  PodeTokenUpdated
} from "../generated/schema"

export function handleAdminAdded(event: AdminAddedEvent): void {
  let entity = new AdminAdded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAdminRemoved(event: AdminRemovedEvent): void {
  let entity = new AdminRemoved(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.admin = event.params.admin

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleAdminRevoked(event: AdminRevokedEvent): void {
  let entity = new AdminRevoked(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleMonaTokenUpdated(event: MonaTokenUpdatedEvent): void {
  let entity = new MonaTokenUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.newToken = event.params.newToken

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handlePodeTokenUpdated(event: PodeTokenUpdatedEvent): void {
  let entity = new PodeTokenUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.newToken = event.params.newToken

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
