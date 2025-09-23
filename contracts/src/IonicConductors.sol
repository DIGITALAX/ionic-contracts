// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./IonicErrors.sol";
import "./IonicAccessControl.sol";
import "./IonicLibrary.sol";
import "./IonicReactionPacks.sol";

contract IonicConductors {
    IonicAccessControl public accessControl;
    uint256 private conductorCount;
    uint256 private reviewCount;
    uint256 public constant MAX_TRUST_SCORE = 100;
    uint256 public constant MIN_TRUST_SCORE = 1;
    uint256 public constant ACTIVITY_INVITE_THRESHOLD = 5;
    uint256 public constant TRUST_INVITE_THRESHOLD = 50;
    address public appraisals;
    address public designers;
    IonicReactionPacks public reactionPacks;
    string public symbol;
    string public name;

    mapping(uint256 => IonicLibrary.Conductor) private _conductors;
    mapping(uint256 => IonicLibrary.Review) private _reviews;
    mapping(address => IonicLibrary.Reviewer) private _reviewers;

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

    event ConductorRegistered(
        address indexed wallet,
        uint256 indexed conductorId,
        string uri
    );
    event ConductorDeleted(uint256 indexed conductorId, address wallet);
    event ConductorUpdated(uint256 indexed conductorId, string uri);
    event ConductorStatsUpdated(
        uint256 indexed conductorId,
        uint256 appraisalCount,
        uint256 averageScore
    );
    event ReviewerURIUpdated(address indexed reviewer, string uri);
    event ReviewSubmitted(
        address indexed reviewer,
        uint256 indexed conductorId,
        uint256 indexed reviewId,
        uint256 reviewScore
    );

    constructor(address _accessControl) {
        conductorCount = 0;
        reviewCount = 0;
        symbol = "HOL";
        name = "Conductor";
        accessControl = IonicAccessControl(_accessControl);
    }

    function registerProfile(string memory uri) external onlyConductor {
        conductorCount++;

        _conductors[conductorCount] = IonicLibrary.Conductor({
            wallet: msg.sender,
            conductorId: conductorCount,
            uri: uri,
            stats: IonicLibrary.ConductorStats({
                appraisalCount: 0,
                totalScore: 0,
                averageScore: 0,
                reviewCount: 0,
                totalReviewScore: 0,
                averageReviewScore: 0,
                inviteCount: 0,
                availableInvites: 1,
                appraisalIds: new uint256[](0),
                reviewIds: new uint256[](0),
                invitedDesigners: new uint256[](0)
            })
        });

        emit ConductorRegistered(msg.sender, conductorCount, uri);
    }

    function deleteProfile(uint256 conductorId) external onlyConductor {
        delete _conductors[conductorId];
        emit ConductorDeleted(conductorId, msg.sender);
    }

    function updateProfile(
        uint256 conductorId,
        string memory uri
    ) external onlyConductor {
        IonicLibrary.Conductor storage conductor = _conductors[conductorId];

        if (conductor.conductorId == 0 || conductor.wallet != msg.sender) {
            revert IonicErrors.ConductorNotFound();
        }

        conductor.uri = uri;
        emit ConductorUpdated(conductorId, uri);
    }

    function updateConductorStats(
        uint256 conductorId,
        uint256 appraisalId,
        uint256 score
    ) external {
        if (msg.sender != appraisals) {
            revert IonicErrors.Unauthorized();
        }

        IonicLibrary.Conductor storage conductor = _conductors[conductorId];

        if (conductor.conductorId == 0) {
            revert IonicErrors.ConductorNotFound();
        }

        conductor.stats.appraisalCount++;
        conductor.stats.totalScore += score;
        conductor.stats.averageScore =
            conductor.stats.totalScore /
            conductor.stats.appraisalCount;
        conductor.stats.appraisalIds.push(appraisalId);

        if (conductor.stats.appraisalCount % 10 == 0) {
            conductor.stats.availableInvites++;
        }

        emit ConductorStatsUpdated(
            conductorId,
            conductor.stats.appraisalCount,
            conductor.stats.averageScore
        );
    }

    function submitReview(
        uint256 conductorId,
        uint256 reviewScore,
        string memory uri,
        IonicLibrary.ReactionUsage[] memory reactions
    ) external {
        if (reviewScore < MIN_TRUST_SCORE || reviewScore > MAX_TRUST_SCORE) {
            revert IonicErrors.InvalidReviewScore();
        }

        IonicLibrary.Conductor storage conductor = _conductors[conductorId];
        if (conductor.conductorId == 0) {
            revert IonicErrors.ConductorNotFound();
        }

        _validateReactions(msg.sender, reactions);

        reviewCount++;

        _reviews[reviewCount] = IonicLibrary.Review({
            reviewer: msg.sender,
            reviewId: reviewCount,
            conductorId: conductorId,
            reviewScore: reviewScore,
            timestamp: block.timestamp,
            uri: uri,
            reactions: new IonicLibrary.ReactionUsage[](0)
        });

        for (uint256 i = 0; i < reactions.length; i++) {
            _reviews[reviewCount].reactions.push(reactions[i]);
        }

        if (_reviewers[msg.sender].reviewer == address(0)) {
            _reviewers[msg.sender].reviewer = msg.sender;
            _reviewers[msg.sender].uri = "";
        }

        IonicLibrary.Reviewer storage reviewer = _reviewers[msg.sender];
        reviewer.stats.reviewCount++;
        reviewer.stats.totalScore += reviewScore;
        reviewer.stats.averageScore = reviewer.stats.totalScore / reviewer.stats.reviewCount;
        reviewer.stats.lastReviewTimestamp = block.timestamp;
        reviewer.stats.scoreDistribution[reviewScore]++;
        reviewer.stats.reviewIds.push(reviewCount);

        conductor.stats.reviewCount++;
        conductor.stats.totalReviewScore += reviewScore;
        conductor.stats.averageReviewScore =
            conductor.stats.totalReviewScore /
            conductor.stats.reviewCount;
        conductor.stats.reviewIds.push(reviewCount);

        emit ReviewSubmitted(msg.sender, conductorId, reviewCount, reviewScore);
    }

    function updateReviewerURI(string memory uri) external {
        if (_reviewers[msg.sender].reviewer == address(0)) {
            _reviewers[msg.sender].reviewer = msg.sender;
        }

        _reviewers[msg.sender].uri = uri;

        emit ReviewerURIUpdated(msg.sender, uri);
    }

    function getConductor(
        uint256 conductorId
    ) external view returns (IonicLibrary.Conductor memory) {
        return _conductors[conductorId];
    }

    function getConductorCount() public view returns (uint256) {
        return conductorCount;
    }

    function getReviewCount() external view returns (uint256) {
        return reviewCount;
    }

    function setAccessControl(address _accessControl) public onlyAdmin {
        accessControl = IonicAccessControl(_accessControl);
    }

    function updateConductorInviteStats(
        uint256 conductorId,
        uint256 designerId,
        bool returning
    ) external {
        if (msg.sender != designers && !accessControl.isAdmin(msg.sender)) {
            revert IonicErrors.Unauthorized();
        }

        IonicLibrary.Conductor storage conductor = _conductors[conductorId];
        if (conductor.conductorId == 0) {
            revert IonicErrors.ConductorNotFound();
        }

        if (returning) {
            conductor.stats.availableInvites++;
        } else {
            conductor.stats.inviteCount++;
            conductor.stats.availableInvites--;
            conductor.stats.invitedDesigners.push(designerId);
        }
    }

    function getConductorByWallet(
        address wallet
    ) external view returns (IonicLibrary.Conductor memory) {
        for (uint256 i = 1; i <= conductorCount; i++) {
            if (_conductors[i].wallet == wallet) {
                return _conductors[i];
            }
        }
        revert IonicErrors.ConductorNotFound();
    }

    function getReview(
        uint256 reviewId
    ) external view returns (IonicLibrary.Review memory) {
        return _reviews[reviewId];
    }

    function getReviewer(
        address reviewer
    ) external view returns (IonicLibrary.Reviewer memory) {
        return _reviewers[reviewer];
    }

    function setAppraisals(address _appraisals) public onlyAdmin {
        appraisals = _appraisals;
    }

    function _validateReactions(
        address user,
        IonicLibrary.ReactionUsage[] memory reactions
    ) private view {
        for (uint256 i = 0; i < reactions.length; i++) {
            if (reactions[i].count == 0) {
                revert IonicErrors.InvalidScore();
            }

            IonicLibrary.Reaction memory reaction = reactionPacks.getReaction(
                reactions[i].reactionId
            );
            if (reaction.reactionId == 0) {
                revert IonicErrors.ReactionPackNotFound();
            }

            uint256 userBalance = 0;
            for (uint256 j = 0; j < reaction.tokenIds.length; j++) {
                try reactionPacks.ownerOf(reaction.tokenIds[j]) returns (
                    address owner
                ) {
                    if (owner == user) {
                        userBalance++;
                    }
                } catch {
                    continue;
                }
            }

            if (userBalance < reactions[i].count) {
                revert IonicErrors.InsufficientBalance();
            }
        }
    }

    function setDesigners(address _designers) public onlyAdmin {
        designers = _designers;
    }

    function setReactionPacks(address _reactionPacks) public onlyAdmin {
        reactionPacks = IonicReactionPacks(_reactionPacks);
    }
}
