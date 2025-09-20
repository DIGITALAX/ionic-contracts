// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./Errors.sol";
import "./AccessControl.sol";
import "./Library.sol";
import "./Holders.sol";

contract Designers {
    AccessControl public accessControl;
    Holders public holders;
    uint256 private designerCount;

    mapping(uint256 => Library.Designer) private _designers;
    mapping(address => uint256) private _designerLookup;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert Errors.Unauthorized();
        }
        _;
    }

    modifier onlyHolder() {
        if (!accessControl.isHolder(msg.sender)) {
            revert Errors.Unauthorized();
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

    constructor(address _accessControl, address _holders) {
        accessControl = AccessControl(_accessControl);
        holders = Holders(_holders);
        designerCount = 0;
    }

    function inviteDesigner(
        address designer,
        uint256 holderId
    ) external onlyHolder {
        if (_designers[_designerLookup[designer]].active) {
            revert Errors.AlreadyExists();
        }

        Library.Holder memory holder = holders.getHolder(holderId);

        if (holder.stats.availableInvites == 0) {
            revert Errors.NoInvitesAvailable();
        }

        uint256 designerId = _designerLookup[designer];

        if (designerId == 0) {
            designerCount++;
            designerId = designerCount;

            _designers[designerId] = Library.Designer({
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

        _updateHolderInviteStats(holder.holderId, designerId);

        emit DesignerInvited(designer, msg.sender, designerId);
    }

    function setDesignerURI(uint256 designerId, string memory uri) public {
        if (_designers[designerId].wallet != msg.sender) {
            revert Errors.Unauthorized();
        }

        _designers[designerId].uri = uri;

        emit DesignerURI(designerId, uri);
    }

    function deactivateDesigner(uint256 designerId) external {
        Library.Designer storage designer = _designers[designerId];

        if (designer.designerId == 0) {
            revert Errors.DesignerNotFound();
        }

        if (!designer.active) {
            revert Errors.DesignerNotActive();
        }

        if (
            designer.invitedBy != msg.sender &&
            !accessControl.isAdmin(msg.sender)
        ) {
            revert Errors.OnlyInviter();
        }

        designer.active = false;

        Library.Holder memory inviter = holders.getHolderByWallet(
            designer.invitedBy
        );
        _returnInviteToHolder(inviter.holderId);

        emit DesignerDeactivated(designerId, msg.sender);
    }

    function _updateHolderInviteStats(
        uint256 holderId,
        uint256 designerId
    ) private {
        holders.updateHolderInviteStats(holderId, designerId, false);
    }

    function _returnInviteToHolder(uint256 holderId) private {
        holders.updateHolderInviteStats(holderId, 0, true);
    }

    function getDesigner(
        uint256 designerId
    ) external view returns (Library.Designer memory) {
        return _designers[designerId];
    }

    function getDesignerByWallet(
        address wallet
    ) external view returns (Library.Designer memory) {
        uint256 designerId = _designerLookup[wallet];
        if (designerId == 0) {
            revert Errors.DesignerNotFound();
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
        accessControl = AccessControl(_accessControl);
    }

    function setHolders(address _holders) external onlyAdmin {
        holders = Holders(_holders);
    }
}
