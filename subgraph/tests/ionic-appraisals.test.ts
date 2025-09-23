import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { AppraisalCreated } from "../generated/schema"
import { AppraisalCreated as AppraisalCreatedEvent } from "../generated/IonicAppraisals/IonicAppraisals"
import { handleAppraisalCreated } from "../src/ionic-appraisals"
import { createAppraisalCreatedEvent } from "./ionic-appraisals-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let appraiser = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let nftId = BigInt.fromI32(234)
    let conductorId = BigInt.fromI32(234)
    let appraisalId = BigInt.fromI32(234)
    let overallScore = BigInt.fromI32(234)
    let newAppraisalCreatedEvent = createAppraisalCreatedEvent(
      appraiser,
      nftId,
      conductorId,
      appraisalId,
      overallScore
    )
    handleAppraisalCreated(newAppraisalCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AppraisalCreated created and stored", () => {
    assert.entityCount("AppraisalCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AppraisalCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "appraiser",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "AppraisalCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "nftId",
      "234"
    )
    assert.fieldEquals(
      "AppraisalCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "conductorId",
      "234"
    )
    assert.fieldEquals(
      "AppraisalCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "appraisalId",
      "234"
    )
    assert.fieldEquals(
      "AppraisalCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "overallScore",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
