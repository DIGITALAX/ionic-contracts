import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { ConductorDeleted } from "../generated/schema"
import { ConductorDeleted as ConductorDeletedEvent } from "../generated/IonicConductors/IonicConductors"
import { handleConductorDeleted } from "../src/ionic-conductors"
import { createConductorDeletedEvent } from "./ionic-conductors-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let conductorId = BigInt.fromI32(234)
    let wallet = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let newConductorDeletedEvent = createConductorDeletedEvent(
      conductorId,
      wallet
    )
    handleConductorDeleted(newConductorDeletedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("ConductorDeleted created and stored", () => {
    assert.entityCount("ConductorDeleted", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "ConductorDeleted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "conductorId",
      "234"
    )
    assert.fieldEquals(
      "ConductorDeleted",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "wallet",
      "0x0000000000000000000000000000000000000001"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
