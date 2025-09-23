// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./IonicErrors.sol";
import "./IonicAccessControl.sol";
import "./IonicLibrary.sol";
import "./IonicDesigners.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IonicReactionPacks is ERC721 {
    IonicAccessControl public accessControl;
    IonicDesigners public designers;
    uint256 private _packCount;
    uint256 private _reactionCount;
    uint256 private _tokenIdCounter;
    uint256 private _purchaseCount;
    uint256 public defaultPriceIncrement;
    uint256 public defaultBasePrice;
    uint256 public constant MAX_CONDUCTOR_SPOTS = 10;
    uint256 public constant MIN_CONDUCTOR_SPOTS = 1;
    uint256 public constant REVENUE_SHARE_PERCENTAGE = 10;

    mapping(uint256 => IonicLibrary.ReactionPack) private _reactionPacks;
    mapping(uint256 => IonicLibrary.Reaction) private _reactions;
    mapping(uint256 => IonicLibrary.Purchase) private _purchases;
    mapping(uint256 => uint256[]) private _packPurchases;
    mapping(address => uint256[]) private _buyerPurchases;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert IonicErrors.Unauthorized();
        }
        _;
    }

    modifier onlyDesigner() {
        if (!designers.isDesigner(msg.sender)) {
            revert IonicErrors.DesignerNotFound();
        }
        _;
    }

    event ReactionPackCreated(
        address indexed designer,
        uint256 indexed packId,
        uint256 basePrice,
        uint256 maxEditions,
        uint256 conductorReservedSpots
    );
    event ReactionAdded(
        uint256 indexed packId,
        uint256 indexed reactionId,
        string reactionUri
    );
    event PackPurchased(
        address indexed buyer,
        uint256 indexed purchaseId,
        uint256 indexed packId,
        uint256 price,
        uint256 editionNumber
    );

    constructor(
        address _accessControl,
        address _designers,
        uint256 _defaultBasePrice,
        uint256 _defaultPriceIncrement
    ) ERC721("Reaction Packs", "REACT") {
        accessControl = IonicAccessControl(_accessControl);
        designers = IonicDesigners(_designers);
        defaultBasePrice = _defaultBasePrice;
        defaultPriceIncrement = _defaultPriceIncrement;
        _packCount = 0;
        _reactionCount = 0;
        _tokenIdCounter = 0;
        _purchaseCount = 0;
    }

    function createReactionPack(
        uint256 maxEditions,
        uint256 conductorReservedSpots,
        string memory packUri,
        string[] memory reactionUris
    ) external onlyDesigner returns (uint256) {
        if (
            conductorReservedSpots < MIN_CONDUCTOR_SPOTS ||
            conductorReservedSpots > MAX_CONDUCTOR_SPOTS
        ) {
            revert IonicErrors.InvalidPrice();
        }

        if (maxEditions == 0 || reactionUris.length == 0) {
            revert IonicErrors.InvalidPrice();
        }

        _packCount++;

        _reactionPacks[_packCount] = IonicLibrary.ReactionPack({
            designer: msg.sender,
            packId: _packCount,
            currentPrice: defaultBasePrice,
            maxEditions: maxEditions,
            soldCount: 0,
            conductorReservedSpots: conductorReservedSpots,
            active: true,
            packUri: packUri,
            reactionIds: new uint256[](0),
            buyers: new address[](0),
            buyerShares: new uint256[](0)
        });

        for (uint256 i = 0; i < reactionUris.length; i++) {
            _reactionCount++;

            _reactions[_reactionCount] = IonicLibrary.Reaction({
                reactionId: _reactionCount,
                packId: _packCount,
                reactionUri: reactionUris[i],
                tokenIds: new uint256[](0)
            });

            _reactionPacks[_packCount].reactionIds.push(_reactionCount);

            emit ReactionAdded(_packCount, _reactionCount, reactionUris[i]);
        }

        emit ReactionPackCreated(
            msg.sender,
            _packCount,
            defaultBasePrice,
            maxEditions,
            conductorReservedSpots
        );

        return _packCount;
    }

    function purchaseReactionPack(uint256 packId) external {
        IonicLibrary.ReactionPack storage pack = _reactionPacks[packId];

        if (pack.packId == 0) {
            revert IonicErrors.ReactionPackNotFound();
        }

        if (!pack.active) {
            revert IonicErrors.ReactionPackNotActive();
        }

        if (pack.soldCount >= pack.maxEditions) {
            revert IonicErrors.SoldOut();
        }

        bool isConductor = accessControl.isConductor(msg.sender);

        if (pack.soldCount < pack.conductorReservedSpots && !isConductor) {
            revert IonicErrors.ConductorSpotsOnly();
        }

        uint256 purchasePrice = pack.currentPrice;
        IERC20 monaToken = IERC20(accessControl.monaToken());
        if (monaToken.balanceOf(msg.sender) < purchasePrice) {
            revert IonicErrors.InsufficientBalance();
        }

        if (monaToken.allowance(msg.sender, address(this)) < purchasePrice) {
            revert IonicErrors.InsufficientBalance();
        }

        _distributeRevenue(pack, purchasePrice, msg.sender, address(monaToken));

        pack.soldCount++;
        pack.currentPrice += defaultPriceIncrement;
        pack.buyers.push(msg.sender);

        uint256 shareWeight = _calculateBuyerShare(pack.soldCount);
        pack.buyerShares.push(shareWeight);
        _purchaseCount++;

        _purchases[_purchaseCount] = IonicLibrary.Purchase({
            buyer: msg.sender,
            purchaseId: _purchaseCount,
            packId: packId,
            price: purchasePrice,
            editionNumber: pack.soldCount,
            shareWeight: shareWeight,
            timestamp: block.timestamp
        });

        _packPurchases[packId].push(_purchaseCount);
        _buyerPurchases[msg.sender].push(_purchaseCount);

        for (uint256 i = 0; i < pack.reactionIds.length; i++) {
            _tokenIdCounter++;
            _mint(msg.sender, _tokenIdCounter);
            _reactions[pack.reactionIds[i]].tokenIds.push(_tokenIdCounter);
        }

        emit PackPurchased(msg.sender, _purchaseCount, packId, purchasePrice, pack.soldCount);
    }

    function _distributeRevenue(
        IonicLibrary.ReactionPack storage pack,
        uint256 price,
        address buyer,
        address monaToken
    ) private {
        if (pack.soldCount == 0) {
            IERC20(monaToken).transferFrom(buyer, pack.designer, price);
            return;
        }

        uint256 totalShares = 0;
        for (uint256 i = 0; i < pack.buyerShares.length; i++) {
            totalShares += pack.buyerShares[i];
        }

        uint256 designerShare = (price * (100 - REVENUE_SHARE_PERCENTAGE)) /
            100;
        uint256 buyerSharePool = price - designerShare;

        IERC20(monaToken).transferFrom(buyer, pack.designer, designerShare);

        for (uint256 i = 0; i < pack.buyers.length; i++) {
            uint256 buyerPayout = (buyerSharePool * pack.buyerShares[i]) /
                totalShares;
            if (buyerPayout > 0) {
                IERC20(monaToken).transferFrom(buyer, pack.buyers[i], buyerPayout);
            }
        }
    }

    function _calculateBuyerShare(
        uint256 editionNumber
    ) private pure returns (uint256) {
        return 100 / editionNumber;
    }

    function getReactionPack(
        uint256 packId
    ) external view returns (IonicLibrary.ReactionPack memory) {
        return _reactionPacks[packId];
    }

    function getReaction(
        uint256 reactionId
    ) external view returns (IonicLibrary.Reaction memory) {
        return _reactions[reactionId];
    }

    function getPackCount() external view returns (uint256) {
        return _packCount;
    }

    function getReactionCount() external view returns (uint256) {
        return _reactionCount;
    }

    function getPurchase(
        uint256 purchaseId
    ) external view returns (IonicLibrary.Purchase memory) {
        return _purchases[purchaseId];
    }

    function getPackPurchases(
        uint256 packId
    ) external view returns (uint256[] memory) {
        return _packPurchases[packId];
    }

    function getBuyerPurchases(
        address buyer
    ) external view returns (uint256[] memory) {
        return _buyerPurchases[buyer];
    }

    function getPurchaseCount() external view returns (uint256) {
        return _purchaseCount;
    }

    function setDefaultPrices(
        uint256 basePrice,
        uint256 priceIncrement
    ) external onlyAdmin {
        defaultBasePrice = basePrice;
        defaultPriceIncrement = priceIncrement;
    }

    function setAccessControl(address _accessControl) external onlyAdmin {
        accessControl = IonicAccessControl(_accessControl);
    }

    function setDesigners(address _designers) external onlyAdmin {
        designers = IonicDesigners(_designers);
    }
}
