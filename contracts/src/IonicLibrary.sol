// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;

contract IonicLibrary {
    enum TokenType {
        ERC721,
        ERC1155,
        ERC998
    }

    struct Conductor {
        address wallet;
        uint256 conductorId;
        string uri;
        ConductorStats stats;
    }

    struct ConductorStats {
        uint256 appraisalCount;
        uint256 totalScore;
        uint256 averageScore;
        uint256 reviewCount;
        uint256 totalReviewScore;
        uint256 averageReviewScore;
        uint256 inviteCount;
        uint256 availableInvites;
        uint256[] appraisalIds;
        uint256[] reviewIds;
        uint256[] invitedDesigners;
    }

    struct Review {
        address reviewer;
        uint256 reviewId;
        uint256 conductorId;
        uint256 reviewScore;
        uint256 timestamp;
        string uri;
        ReactionUsage[] reactions;
    }

    struct NFT {
        address nftContract;
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
        address nftContract;
        uint256 appraisalId;
        uint256 nftId;
        uint256 conductorId;
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
        uint256 conductorReservedSpots;
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

    struct ReviewerStats {
        uint256 reviewCount;
        uint256 totalScore;
        uint256 averageScore;
        uint256 lastReviewTimestamp;
        uint256[101] scoreDistribution;
        uint256[] reviewIds;
    }

    struct Reviewer {
        address reviewer;
        string uri;
        ReviewerStats stats;
    }

    struct Token {
        address minter;
        uint256 reason;
    }

    struct Minter {
        address minter;
        uint256 reason;
    }
}
