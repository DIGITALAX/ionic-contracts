// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;

contract Library {
    enum TokenType {
        ERC721,
        ERC1155,
        ERC998
    }

    struct Holder {
        address wallet;
        uint256 holderId;
        string uri;
        HolderStats stats;
    }

    struct HolderStats {
        uint256 appraisalCount;
        uint256 totalScore;
        uint256 averageScore;
        uint256 trustCount;
        uint256 totalTrustScore;
        uint256 averageTrustScore;
        uint256 inviteCount;
        uint256 availableInvites;
        uint256[] appraisalIds;
        uint256[] trustIds;
        uint256[] invitedDesigners;
    }

    struct Trust {
        address reviewer;
        uint256 trustId;
        uint256 holderId;
        uint256 trustScore;
        uint256 timestamp;
        string commentsUri;
        ReactionUsage[] reactions;
    }

    struct NFT {
        address contractAddress;
        address submitter;
        bool active;
        TokenType tokenType;
        uint256 nftId;
        uint256 tokenId;
        uint256 appraisalCount;
        uint256 totalScore;
        uint256 averageScore;
    }

    struct ReactionUsage {
        uint256 reactionId;
        uint256 count;
    }

    struct Appraisal {
        address appraiser;
        uint256 appraisalId;
        uint256 nftId;
        uint256 holderId;
        uint256 overallScore;
        uint256 timestamp;
        string uri;
        ReactionUsage[] reactions;
    }

    struct Designer {
        address wallet;
        address invitedBy;
        bool active;
        uint256 designerId;
        uint256 inviteTimestamp;
        uint256 packCount;
        uint256[] reactionPackIds;
        string uri;
    }

    struct ReactionPack {
        address designer;
        uint256 packId;
        uint256 currentPrice;
        uint256 maxEditions;
        uint256 soldCount;
        uint256 holderReservedSpots;
        bool active;
        string packUri;
        uint256[] reactionIds;
        address[] buyers;
        uint256[] buyerShares;
    }

    struct Reaction {
        uint256 reactionId;
        uint256 packId;
        string reactionUri;
        uint256[] tokenIds;
    }

    struct Purchase {
        address buyer;
        uint256 purchaseId;
        uint256 packId;
        uint256 price;
        uint256 editionNumber;
        uint256 shareWeight;
        uint256 timestamp;
    }

    struct AppraisalStats {
        uint256 totalAppraisals;
        uint256 totalNFTs;
        uint256[101] scoreDistribution;
    }
}
