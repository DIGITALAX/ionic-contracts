// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./Errors.sol";
import "./AccessControl.sol";
import "./Library.sol";
import "./Holders.sol";
import "./ReactionPacks.sol";

contract Appraisals {
    AccessControl public accessControl;
    Holders public holders;
    ReactionPacks public reactionPacks;

    uint256 private nftCount;
    uint256 private appraisalCount;
    uint256 public constant MAX_SCORE = 100;
    uint256 public constant MIN_SCORE = 1;
    Library.AppraisalStats private _globalStats;

    mapping(uint256 => Library.NFT) private _nfts;
    mapping(uint256 => Library.Appraisal) private _appraisals;
    mapping(bytes32 => uint256) private _nftLookup;
    mapping(uint256 => mapping(uint256 => uint256)) private _latestAppraisal;
    mapping(uint256 => uint256[]) private _nftAppraisals;

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

    event NFTSubmitted(
        uint256 indexed nftId,
        address indexed contractAddress,
        uint256 indexed tokenId,
        address submitter,
        Library.TokenType tokenType
    );

    event NFTRemoved(uint256 indexed nftId, address indexed submitter);

    event AppraisalCreated(
        address indexed appraiser,
        uint256 indexed nftId,
        uint256 indexed holderId,
        uint256 appraisalId,
        uint256 overallScore
    );

    constructor(address _accessControl, address _holders) {
        accessControl = AccessControl(_accessControl);
        holders = Holders(_holders);
        nftCount = 0;
        appraisalCount = 0;
    }

    function submitNFT(
        uint256 tokenId,
        address contractAddress,
        Library.TokenType tokenType
    ) external returns (uint256) {
        bytes32 nftKey = keccak256(abi.encodePacked(contractAddress, tokenId));

        if (_nftLookup[nftKey] != 0) {
            revert Errors.AlreadyExists();
        }

        nftCount++;

        _nfts[nftCount] = Library.NFT({
            contractAddress: contractAddress,
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
        Library.NFT storage nft = _nfts[nftId];

        if (nft.nftId == 0) {
            revert Errors.NFTNotFound();
        }

        if (nft.submitter != msg.sender) {
            revert Errors.OnlySubmitter();
        }

        nft.active = false;
        _globalStats.totalNFTs--;

        emit NFTRemoved(nftId, msg.sender);
    }

    function createAppraisal(
        uint256 nftId,
        uint256 holderId,
        uint256 overallScore,
        string memory uri,
        Library.ReactionUsage[] memory reactions
    ) external onlyHolder {
        Library.NFT storage nft = _nfts[nftId];

        if (nft.nftId == 0) {
            revert Errors.NFTNotFound();
        }

        if (!nft.active) {
            revert Errors.NFTNotActive();
        }

        if (overallScore < MIN_SCORE || overallScore > MAX_SCORE) {
            revert Errors.InvalidScore();
        }


        Library.Holder memory holder = holders.getHolder(holderId);
        if (holder.holderId == 0 || holder.wallet != msg.sender) {
            revert Errors.HolderNotFound();
        }

        _validateReactions(msg.sender, reactions);

        appraisalCount++;

        _appraisals[appraisalCount] = Library.Appraisal({
            appraiser: msg.sender,
            appraisalId: appraisalCount,
            nftId: nftId,
            holderId: holderId,
            overallScore: overallScore,
            timestamp: block.timestamp,
            uri: uri,
            reactions: new Library.ReactionUsage[](0)
        });

        for (uint256 i = 0; i < reactions.length; i++) {
            _appraisals[appraisalCount].reactions.push(reactions[i]);
        }

        _nftAppraisals[nftId].push(appraisalCount);
        
        uint256 previousAppraisalId = _latestAppraisal[nftId][holderId];
        
        if (previousAppraisalId == 0) {
            nft.appraisalCount++;
            nft.totalScore += overallScore;
        } else {
            uint256 previousScore = _appraisals[previousAppraisalId].overallScore;
            nft.totalScore = nft.totalScore - previousScore + overallScore;
        }
        
        _latestAppraisal[nftId][holderId] = appraisalCount;
        nft.averageScore = nft.totalScore / nft.appraisalCount;

        _globalStats.totalAppraisals++;
        _globalStats.scoreDistribution[overallScore]++;

        holders.updateHolderStats(holderId, appraisalCount, overallScore);

        emit AppraisalCreated(
            msg.sender,
            nftId,
            holderId,
            appraisalCount,
            overallScore
        );

    }

    function getNFT(uint256 nftId) external view returns (Library.NFT memory) {
        return _nfts[nftId];
    }

    function getAppraisal(
        uint256 appraisalId
    ) external view returns (Library.Appraisal memory) {
        return _appraisals[appraisalId];
    }

    function getNFTAppraisals(
        uint256 nftId
    ) external view returns (uint256[] memory) {
        return _nftAppraisals[nftId];
    }

    function hasAppraised(
        uint256 nftId,
        uint256 holderId
    ) external view returns (bool) {
        return _latestAppraisal[nftId][holderId] > 0;
    }

    function getLatestAppraisal(
        uint256 nftId,
        uint256 holderId
    ) external view returns (uint256) {
        return _latestAppraisal[nftId][holderId];
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
        returns (Library.AppraisalStats memory)
    {
        return _globalStats;
    }

    function getScoreDistribution(uint256 score) external view returns (uint256) {
        require(score >= MIN_SCORE && score <= MAX_SCORE, "Invalid score");
        return _globalStats.scoreDistribution[score];
    }

    function setAccessControl(address _accessControl) external onlyAdmin {
        accessControl = AccessControl(_accessControl);
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

    function setHolders(address _holders) external onlyAdmin {
        holders = Holders(_holders);
    }
    
    function setReactionPacks(address _reactionPacks) external onlyAdmin {
        reactionPacks = ReactionPacks(_reactionPacks);
    }
}
