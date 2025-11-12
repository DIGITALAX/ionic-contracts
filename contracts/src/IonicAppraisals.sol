// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./IonicErrors.sol";
import "./IonicAccessControl.sol";
import "./IonicLibrary.sol";
import "./IonicConductors.sol";
import "./IonicReactionPacks.sol";

contract IonicAppraisals {
    IonicAccessControl public accessControl;
    IonicConductors public conductors;
    IonicReactionPacks public reactionPacks;

    uint256 private nftCount;
    uint256 private appraisalCount;
    uint256 public constant MAX_SCORE = 100;
    uint256 public constant MIN_SCORE = 1;
    IonicLibrary.AppraisalStats private _globalStats;

    mapping(uint256 => IonicLibrary.NFT) private _nfts;
    mapping(uint256 => IonicLibrary.Appraisal) private _appraisals;
    mapping(bytes32 => uint256) private _nftLookup;
    mapping(uint256 => mapping(uint256 => uint256)) private _latestAppraisal;
    mapping(uint256 => uint256[]) private _nftAppraisals;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert IonicErrors.Unauthorized();
        }
        _;
    }

    modifier onlyConductor(uint256 tokenId) {
        if (!accessControl.isConductor(msg.sender, tokenId)) {
            revert IonicErrors.Unauthorized();
        }

        _;
    }
    event NFTSubmitted(
        uint256 indexed nftId,
        address indexed contractAddress,
        uint256 indexed tokenId,
        address submitter,
        IonicLibrary.TokenType tokenType
    );

    event NFTRemoved(uint256 indexed nftId, address indexed submitter);

    event AppraisalCreated(
        address indexed appraiser,
        uint256 indexed nftId,
        uint256 indexed conductorId,
        uint256 appraisalId,
        uint256 overallScore
    );

    constructor(address _accessControl, address _conductors) {
        accessControl = IonicAccessControl(_accessControl);
        conductors = IonicConductors(_conductors);
        nftCount = 0;
        appraisalCount = 0;
    }

    function submitNFT(
        uint256 tokenId,
        address contractAddress,
        IonicLibrary.TokenType tokenType
    ) external returns (uint256) {
        bytes32 nftKey = keccak256(abi.encodePacked(contractAddress, tokenId));

        if (_nftLookup[nftKey] != 0) {
            revert IonicErrors.AlreadyExists();
        }

        nftCount++;

        _nfts[nftCount] = IonicLibrary.NFT({
            nftContract: contractAddress,
            submitter: msg.sender,
            active: true,
            tokenType: tokenType,
            nftId: nftCount,
            tokenId: tokenId,
            appraisalCount: 0,
            totalScore: 0,
            averageScore: 0
        });

        _nftLookup[nftKey] = nftCount;
        _globalStats.totalNFTs++;

        emit NFTSubmitted(
            nftCount,
            contractAddress,
            tokenId,
            msg.sender,
            tokenType
        );

        return nftCount;
    }

    function removeNFT(uint256 nftId) external {
        IonicLibrary.NFT storage nft = _nfts[nftId];

        if (nft.nftId == 0) {
            revert IonicErrors.NFTNotFound();
        }

        if (nft.submitter != msg.sender) {
            revert IonicErrors.OnlySubmitter();
        }

        nft.active = false;
        _globalStats.totalNFTs--;

        emit NFTRemoved(nftId, msg.sender);
    }

    function createAppraisal(
        address nftContract,
        uint256 nftId,
        uint256 conductorId,
        uint256 overallScore,
        string calldata uri,
        IonicLibrary.ReactionUsage[] calldata reactions
    ) external onlyConductor(conductorId) {
        _createAppraisal(
            nftContract,
            nftId,
            conductorId,
            overallScore,
            uri,
            reactions
        );
    }

    function createAppraisalBatch(
        uint256 conductorId,
        address[] calldata nftContracts,
        uint256[] calldata nftIds,
        uint256[] calldata overallScores,
        string[] calldata uris,
        IonicLibrary.ReactionUsage[][] calldata reactions
    ) external onlyConductor(conductorId) {
        if (
            nftIds.length != overallScores.length ||
            nftIds.length != uris.length ||
            nftIds.length != reactions.length ||
            nftIds.length != nftContracts.length
        ) {
            revert IonicErrors.InvalidInput();
        }

        for (uint256 i; i < nftIds.length; ) {
            _createAppraisal(
                nftContracts[i],
                nftIds[i],
                conductorId,
                overallScores[i],
                uris[i],
                reactions[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function _createAppraisal(
        address nftContract,
        uint256 nftId,
        uint256 conductorId,
        uint256 overallScore,
        string memory uri,
        IonicLibrary.ReactionUsage[] memory reactions
    ) internal {
        _validateAppraisalInputs(nftId, conductorId, overallScore);
        _validateReactions(msg.sender, reactions);

        _updateNFTStats(nftId, conductorId, overallScore);
        uint256 newAppraisalId = _recordAppraisal(
            nftContract,
            nftId,
            conductorId,
            overallScore,
            uri,
            reactions
        );
        _updateGlobalStats(overallScore);
        _notifyConductor(conductorId, newAppraisalId, overallScore);

        emit AppraisalCreated(
            msg.sender,
            nftId,
            conductorId,
            newAppraisalId,
            overallScore
        );
    }

    function _validateAppraisalInputs(
        uint256 nftId,
        uint256 conductorId,
        uint256 overallScore
    ) private view {
        IonicLibrary.NFT storage nft = _nfts[nftId];

        if (nft.nftId == 0) {
            revert IonicErrors.NFTNotFound();
        }

        if (!nft.active) {
            revert IonicErrors.NFTNotActive();
        }

        if (overallScore < MIN_SCORE || overallScore > MAX_SCORE) {
            revert IonicErrors.InvalidScore();
        }

        IonicLibrary.Conductor memory conductor = conductors.getConductor(
            conductorId
        );
        if (conductor.conductorId == 0) {
            revert IonicErrors.ConductorNotFound();
        }
    }

    function _recordAppraisal(
        address nftContract,
        uint256 nftId,
        uint256 conductorId,
        uint256 overallScore,
        string memory uri,
        IonicLibrary.ReactionUsage[] memory reactions
    ) private returns (uint256) {
        appraisalCount++;

        IonicLibrary.Appraisal storage appraisal = _appraisals[appraisalCount];
        appraisal.appraiser = msg.sender;
        appraisal.appraisalId = appraisalCount;
        appraisal.nftContract = nftContract;
        appraisal.nftId = nftId;
        appraisal.conductorId = conductorId;
        appraisal.overallScore = overallScore;
        appraisal.timestamp = block.timestamp;
        appraisal.uri = uri;

        for (uint256 i = 0; i < reactions.length; i++) {
            appraisal.reactions.push(reactions[i]);
        }

        _nftAppraisals[nftId].push(appraisalCount);
        _latestAppraisal[nftId][conductorId] = appraisalCount;

        return appraisalCount;
    }

    function _updateNFTStats(
        uint256 nftId,
        uint256 conductorId,
        uint256 overallScore
    ) private {
        IonicLibrary.NFT storage nft = _nfts[nftId];
        uint256 previousAppraisalId = _latestAppraisal[nftId][conductorId];

        if (previousAppraisalId == 0) {
            nft.appraisalCount++;
            nft.totalScore += overallScore;
        } else {
            uint256 previousScore = _appraisals[previousAppraisalId]
                .overallScore;
            nft.totalScore = nft.totalScore - previousScore + overallScore;
        }

        nft.averageScore = nft.totalScore / nft.appraisalCount;
    }

    function _updateGlobalStats(uint256 overallScore) private {
        _globalStats.totalAppraisals++;
        _globalStats.scoreDistribution[overallScore]++;
    }

    function _notifyConductor(
        uint256 conductorId,
        uint256 appraisalId,
        uint256 overallScore
    ) private {
        conductors.updateConductorStats(conductorId, appraisalId, overallScore);
    }

    function getNFT(
        uint256 nftId
    ) external view returns (IonicLibrary.NFT memory) {
        return _nfts[nftId];
    }

    function getAppraisal(
        uint256 appraisalId
    ) external view returns (IonicLibrary.Appraisal memory) {
        return _appraisals[appraisalId];
    }

    function getNFTAppraisals(
        uint256 nftId
    ) external view returns (uint256[] memory) {
        return _nftAppraisals[nftId];
    }

    function hasAppraised(
        uint256 nftId,
        uint256 conductorId
    ) external view returns (bool) {
        return _latestAppraisal[nftId][conductorId] > 0;
    }

    function getLatestAppraisal(
        uint256 nftId,
        uint256 conductorId
    ) external view returns (uint256) {
        return _latestAppraisal[nftId][conductorId];
    }

    function getNFTCount() external view returns (uint256) {
        return nftCount;
    }

    function getAppraisalCount() external view returns (uint256) {
        return appraisalCount;
    }

    function getGlobalStats()
        external
        view
        returns (IonicLibrary.AppraisalStats memory)
    {
        return _globalStats;
    }

    function getScoreDistribution(
        uint256 score
    ) external view returns (uint256) {
        require(score >= MIN_SCORE && score <= MAX_SCORE, "Invalid score");
        return _globalStats.scoreDistribution[score];
    }

    function setAccessControl(address _accessControl) external onlyAdmin {
        accessControl = IonicAccessControl(_accessControl);
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

    function setConductors(address _conductors) external onlyAdmin {
        conductors = IonicConductors(_conductors);
    }

    function setReactionPacks(address _reactionPacks) external onlyAdmin {
        reactionPacks = IonicReactionPacks(_reactionPacks);
    }
}
