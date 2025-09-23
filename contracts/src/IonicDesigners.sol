// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./IonicErrors.sol";
import "./IonicAccessControl.sol";
import "./IonicLibrary.sol";
import "./IonicConductors.sol";

contract IonicDesigners {
    IonicAccessControl public accessControl;
    IonicConductors public conductors;
    uint256 private designerCount;

    mapping(uint256 => IonicLibrary.Designer) private _designers;
    mapping(address => uint256) private _designerLookup;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert IonicErrors.Unauthorized();
        }
        _;
    }

    modifier onlyConductor() {
        if (!accessControl.isConductor(msg.sender)) {
            revert IonicErrors.Unauthorized();
        }
        _;
    }

    event DesignerInvited(
        address indexed designer,
        address indexed inviter,
        uint256 indexed designerId
    );
    event DesignerURI(uint256 indexed designerId, string uri);
    event DesignerDeactivated(
        uint256 indexed designerId,
        address indexed inviter
    );

    constructor(address _accessControl, address _conductors) {
        accessControl = IonicAccessControl(_accessControl);
        conductors = IonicConductors(_conductors);
        designerCount = 0;
    }

    function inviteDesigner(
        address designer,
        uint256 conductorId
    ) external onlyConductor {
        if (_designers[_designerLookup[designer]].active) {
            revert IonicErrors.AlreadyExists();
        }

        IonicLibrary.Conductor memory conductor = conductors.getConductor(conductorId);

        if (conductor.stats.availableInvites == 0) {
            revert IonicErrors.NoInvitesAvailable();
        }

        uint256 designerId = _designerLookup[designer];

        if (designerId == 0) {
            designerCount++;
            designerId = designerCount;

            _designers[designerId] = IonicLibrary.Designer({
                wallet: designer,
                invitedBy: msg.sender,
                active: true,
                designerId: designerId,
                inviteTimestamp: block.timestamp,
                packCount: 0,
                uri: "",
                reactionPackIds: new uint256[](0)
            });

            _designerLookup[designer] = designerId;
        } else {
            _designers[designerId].invitedBy = msg.sender;
            _designers[designerId].inviteTimestamp = block.timestamp;
            _designers[designerId].active = true;
        }

        _updateConductorInviteStats(conductor.conductorId, designerId);

        emit DesignerInvited(designer, msg.sender, designerId);
    }

    function setDesignerURI(uint256 designerId, string memory uri) public {
        if (_designers[designerId].wallet != msg.sender) {
            revert IonicErrors.Unauthorized();
        }

        _designers[designerId].uri = uri;

        emit DesignerURI(designerId, uri);
    }

    function deactivateDesigner(uint256 designerId) external {
        IonicLibrary.Designer storage designer = _designers[designerId];

        if (designer.designerId == 0) {
            revert IonicErrors.DesignerNotFound();
        }

        if (!designer.active) {
            revert IonicErrors.DesignerNotActive();
        }

        if (
            designer.invitedBy != msg.sender &&
            !accessControl.isAdmin(msg.sender)
        ) {
            revert IonicErrors.OnlyInviter();
        }

        designer.active = false;

        IonicLibrary.Conductor memory inviter = conductors.getConductorByWallet(
            designer.invitedBy
        );
        _returnInviteToConductor(inviter.conductorId);

        emit DesignerDeactivated(designerId, msg.sender);
    }

    function _updateConductorInviteStats(
        uint256 conductorId,
        uint256 designerId
    ) private {
        conductors.updateConductorInviteStats(conductorId, designerId, false);
    }

    function _returnInviteToConductor(uint256 conductorId) private {
        conductors.updateConductorInviteStats(conductorId, 0, true);
    }

    function getDesigner(
        uint256 designerId
    ) external view returns (IonicLibrary.Designer memory) {
        return _designers[designerId];
    }

    function getDesignerByWallet(
        address wallet
    ) external view returns (IonicLibrary.Designer memory) {
        uint256 designerId = _designerLookup[wallet];
        if (designerId == 0) {
            revert IonicErrors.DesignerNotFound();
        }
        return _designers[designerId];
    }

    function isDesigner(address wallet) external view returns (bool) {
        uint256 designerId = _designerLookup[wallet];
        return designerId != 0 && _designers[designerId].active;
    }

    function getDesignerCount() external view returns (uint256) {
        return designerCount;
    }

    function setAccessControl(address _accessControl) external onlyAdmin {
        accessControl = IonicAccessControl(_accessControl);
    }

    function setConductors(address _conductors) external onlyAdmin {
        conductors = IonicConductors(_conductors);
    }
}
