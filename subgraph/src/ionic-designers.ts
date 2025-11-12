import { Bytes, store } from "@graphprotocol/graph-ts";
import {
  DesignerDeactivated as DesignerDeactivatedEvent,
  DesignerInvited as DesignerInvitedEvent,
  DesignerURI as DesignerURIEvent,
  IonicDesigners,
} from "../generated/IonicDesigners/IonicDesigners";
import { Conductor, Designer } from "../generated/schema";
import { IonicConductors } from "../generated/IonicConductors/IonicConductors";
import { BaseMetadata as BaseMetadataTemplate } from "../generated/templates";
export function handleDesignerDeactivated(
  event: DesignerDeactivatedEvent
): void {
  let entity = Designer.load(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.designerId))
  );

  if (entity) {
    store.remove("Designer", entity.id.toHexString());
  }
}

export function handleDesignerInvited(event: DesignerInvitedEvent): void {
  let entity = new Designer(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.designerId))
  );
  entity.wallet = event.params.designer;
  entity.designerId = event.params.designerId;

  let designer = IonicDesigners.bind(event.address);
  let data = designer.getDesigner(event.params.designerId);
  entity.active = data.active;
  entity.inviteTimestamp = event.block.timestamp;
  entity.packCount = data.packCount;
  entity.uri = data.uri;

  let conductor = IonicConductors.bind(designer.conductors());
  let dataConductor = conductor.getConductorByWallet(event.params.inviter);
  entity.invitedBy = Bytes.fromByteArray(
    Bytes.fromBigInt(dataConductor.conductorId)
  );

  let reactionPacks: Bytes[] = [];

  for (let i = 0; i < data.reactionPackIds.length; i++) {
    reactionPacks.push(
      Bytes.fromByteArray(Bytes.fromBigInt(data.reactionPackIds[i]))
    );
  }

  entity.reactionPacks = reactionPacks;

  entity.save();

  let conductorEntity = Conductor.load(
    Bytes.fromByteArray(Bytes.fromBigInt(dataConductor.conductorId))
  );
  if (!conductorEntity) {
    conductorEntity = new Conductor(
      Bytes.fromByteArray(Bytes.fromBigInt(dataConductor.conductorId))
    );
  }
  if (conductorEntity) {
    let designers: Bytes[] | null = conductorEntity.invitedDesigners;
    if (!designers) {
      designers = [];
    }

    designers.push(
      Bytes.fromByteArray(Bytes.fromBigInt(event.params.designerId))
    );
    conductorEntity.inviteCount = dataConductor.stats.inviteCount;
    conductorEntity.availableInvites = dataConductor.stats.availableInvites;
    conductorEntity.invitedDesigners = designers;
    conductorEntity.save();
  }
}

export function handleDesignerURI(event: DesignerURIEvent): void {
  let entity = Designer.load(
    Bytes.fromByteArray(Bytes.fromBigInt(event.params.designerId))
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
