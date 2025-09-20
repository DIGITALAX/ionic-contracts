// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./Errors.sol";
import "./AccessControl.sol";
import "./Library.sol";
import "./ReactionPacks.sol";

contract Holders {
    AccessControl public accessControl;
    uint256 private holderCount;
    uint256 private trustCount;
    uint256 public constant MAX_TRUST_SCORE = 100;
    uint256 public constant MIN_TRUST_SCORE = 1;
    uint256 public constant ACTIVITY_INVITE_THRESHOLD = 5;
    uint256 public constant TRUST_INVITE_THRESHOLD = 50;
    address public appraisals;
    address public designers;
    ReactionPacks public reactionPacks;
    string public symbol;
    string public name;

    mapping(uint256 => Library.Holder) private _holders;
    mapping(uint256 => Library.Trust) private _trusts;

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

    event HolderRegistered(
        address indexed wallet,
        uint256 indexed holderId,
        string uri
    );
    event HolderDeleted(uint256 indexed holderId, address wallet);
    event HolderUpdated(uint256 indexed holderId, string uri);
    event HolderStatsUpdated(
        uint256 indexed holderId,
        uint256 appraisalCount,
        uint256 averageScore
    );
    event TrustSubmitted(
        address indexed reviewer,
        uint256 indexed holderId,
        uint256 indexed trustId,
        uint256 trustScore
    );

    constructor(address _accessControl) {
        holderCount = 0;
        trustCount = 0;
        symbol = "HOL";
        name = "Holder";
        accessControl = AccessControl(_accessControl);
    }

    function registerProfile(string memory uri) external onlyHolder {
        holderCount++;

        _holders[holderCount] = Library.Holder({
            wallet: msg.sender,
            holderId: holderCount,
            uri: uri,
            stats: Library.HolderStats({
                appraisalCount: 0,
                totalScore: 0,
                averageScore: 0,
                trustCount: 0,
                totalTrustScore: 0,
                averageTrustScore: 0,
                inviteCount: 0,
                availableInvites: 1,
                appraisalIds: new uint256[](0),
                trustIds: new uint256[](0),
                invitedDesigners: new uint256[](0)
            })
        });

        emit HolderRegistered(msg.sender, holderCount, uri);
    }

    function deleteProfile(uint256 holderId) external onlyHolder {
        delete _holders[holderId];
        emit HolderDeleted(holderId, msg.sender);
    }

    function updateProfile(
        uint256 holderId,
        string memory uri
    ) external onlyHolder {
        Library.Holder storage holder = _holders[holderId];

        if (holder.holderId == 0 || holder.wallet != msg.sender) {
            revert Errors.HolderNotFound();
        }

        holder.uri = uri;
        emit HolderUpdated(holderId, uri);
    }

    function updateHolderStats(
        uint256 holderId,
        uint256 appraisalId,
        uint256 score
    ) external {
        if (msg.sender != appraisals) {
            revert Errors.Unauthorized();
        }

        Library.Holder storage holder = _holders[holderId];

        if (holder.holderId == 0) {
            revert Errors.HolderNotFound();
        }

        holder.stats.appraisalCount++;
        holder.stats.totalScore += score;
        holder.stats.averageScore =
            holder.stats.totalScore /
            holder.stats.appraisalCount;
        holder.stats.appraisalIds.push(appraisalId);

        if (holder.stats.appraisalCount % 10 == 0) {
            holder.stats.availableInvites++;
        }

        emit HolderStatsUpdated(
            holderId,
            holder.stats.appraisalCount,
            holder.stats.averageScore
        );
    }

    function submitTrust(
        uint256 holderId,
        uint256 trustScore,
        string memory commentsUri,
        Library.ReactionUsage[] memory reactions
    ) external {
        if (trustScore < MIN_TRUST_SCORE || trustScore > MAX_TRUST_SCORE) {
            revert Errors.InvalidTrustScore();
        }

        Library.Holder storage holder = _holders[holderId];
        if (holder.holderId == 0) {
            revert Errors.HolderNotFound();
        }

        _validateReactions(msg.sender, reactions);

        trustCount++;

        _trusts[trustCount] = Library.Trust({
            reviewer: msg.sender,
            trustId: trustCount,
            holderId: holderId,
            trustScore: trustScore,
            timestamp: block.timestamp,
            commentsUri: commentsUri,
            reactions: new Library.ReactionUsage[](0)
        });

        for (uint256 i = 0; i < reactions.length; i++) {
            _trusts[trustCount].reactions.push(reactions[i]);
        }

        holder.stats.trustCount++;
        holder.stats.totalTrustScore += trustScore;
        holder.stats.averageTrustScore =
            holder.stats.totalTrustScore /
            holder.stats.trustCount;
        holder.stats.trustIds.push(trustCount);

        emit TrustSubmitted(msg.sender, holderId, trustCount, trustScore);
    }

    function getHolder(
        uint256 holderId
    ) external view returns (Library.Holder memory) {
        return _holders[holderId];
    }

    function getHolderCount() public view returns (uint256) {
        return holderCount;
    }

    function getTrustCount() external view returns (uint256) {
        return trustCount;
    }

    function setAccessControl(address _accessControl) public onlyAdmin {
        accessControl = AccessControl(_accessControl);
    }

    function updateHolderInviteStats(
        uint256 holderId,
        uint256 designerId,
        bool returning
    ) external {
        if (msg.sender != designers && !accessControl.isAdmin(msg.sender)) {
            revert Errors.Unauthorized();
        }
        
        Library.Holder storage holder = _holders[holderId];
        if (holder.holderId == 0) {
            revert Errors.HolderNotFound();
        }
        
        if (returning) {
            holder.stats.availableInvites++;
        } else {
            holder.stats.inviteCount++;
            holder.stats.availableInvites--;
            holder.stats.invitedDesigners.push(designerId);
        }
    }

    function getHolderByWallet(address wallet) external view returns (Library.Holder memory) {
        for (uint256 i = 1; i <= holderCount; i++) {
            if (_holders[i].wallet == wallet) {
                return _holders[i];
            }
        }
        revert Errors.HolderNotFound();
    }

    function setAppraisals(address _appraisals) public onlyAdmin {
        appraisals = _appraisals;
    }
    
    function _validateReactions(address user, Library.ReactionUsage[] memory reactions) private view {
        for (uint256 i = 0; i < reactions.length; i++) {
            if (reactions[i].count == 0) {
                revert Errors.InvalidScore();
            }
            
            Library.Reaction memory reaction = reactionPacks.getReaction(reactions[i].reactionId);
            if (reaction.reactionId == 0) {
                revert Errors.ReactionPackNotFound();
            }
            
            uint256 userBalance = 0;
            for (uint256 j = 0; j < reaction.tokenIds.length; j++) {
                try reactionPacks.ownerOf(reaction.tokenIds[j]) returns (address owner) {
                    if (owner == user) {
                        userBalance++;
                    }
                } catch {
                    continue;
                }
            }
            
            if (userBalance < reactions[i].count) {
                revert Errors.InsufficientBalance();
            }
        }
    }

    function setDesigners(address _designers) public onlyAdmin {
        designers = _designers;
    }
    
    function setReactionPacks(address _reactionPacks) public onlyAdmin {
        reactionPacks = ReactionPacks(_reactionPacks);
    }
}
