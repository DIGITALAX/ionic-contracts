import { newMockEvent } from "matchstick-as"
import { ethereum, Address } from "@graphprotocol/graph-ts"
import {
  AdminAdded,
  AdminRemoved,
  AdminRevoked,
  MonaTokenUpdated,
  PodeTokenUpdated
} from "../generated/AccessControl/AccessControl"

export function createAdminAddedEvent(admin: Address): AdminAdded {
  let adminAddedEvent = changetype<AdminAdded>(newMockEvent())

  adminAddedEvent.parameters = new Array()

  adminAddedEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )

  return adminAddedEvent
}

export function createAdminRemovedEvent(admin: Address): AdminRemoved {
  let adminRemovedEvent = changetype<AdminRemoved>(newMockEvent())

  adminRemovedEvent.parameters = new Array()

  adminRemovedEvent.parameters.push(
    new ethereum.EventParam("admin", ethereum.Value.fromAddress(admin))
  )

  return adminRemovedEvent
}

export function createAdminRevokedEvent(): AdminRevoked {
  let adminRevokedEvent = changetype<AdminRevoked>(newMockEvent())

  adminRevokedEvent.parameters = new Array()

  return adminRevokedEvent
}

export function createMonaTokenUpdatedEvent(
  newToken: Address
): MonaTokenUpdated {
  let monaTokenUpdatedEvent = changetype<MonaTokenUpdated>(newMockEvent())

  monaTokenUpdatedEvent.parameters = new Array()

  monaTokenUpdatedEvent.parameters.push(
    new ethereum.EventParam("newToken", ethereum.Value.fromAddress(newToken))
  )

  return monaTokenUpdatedEvent
}

export function createPodeTokenUpdatedEvent(
  newToken: Address
): PodeTokenUpdated {
  let podeTokenUpdatedEvent = changetype<PodeTokenUpdated>(newMockEvent())

  podeTokenUpdatedEvent.parameters = new Array()

  podeTokenUpdatedEvent.parameters.push(
    new ethereum.EventParam("newToken", ethereum.Value.fromAddress(newToken))
  )

  return podeTokenUpdatedEvent
}
