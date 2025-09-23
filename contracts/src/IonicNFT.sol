// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./IonicErrors.sol";
import "./IonicAccessControl.sol";
import "./IonicLibrary.sol";
import "./IonicDesigners.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IonicNFT is ERC721 {
    IonicAccessControl public accessControl;
    IonicDesigners public designers;
    uint256 private _tokenCounter;
    IonicLibrary.Minter[] private _mintersList;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert IonicErrors.Unauthorized();
        }
        _;
    }

    event TokenMinted(address indexed minter, uint256 indexed tokenId);
    event TokenURIUpdated(uint256 reason, string uri);
    event MintersAuthorized(IonicLibrary.Minter[] minters);

    mapping(uint256 => IonicLibrary.Token) private _tokens;
    mapping(uint256 => string) private _tokenURIReason;
    mapping(address => bool) private _authorizedMinters;

    constructor(address _accessControl) ERC721("IonicNFT", "IONIC") {
        accessControl = IonicAccessControl(_accessControl);
        _tokenCounter = 0;
    }

    function mint() external {
        if (!_authorizedMinters[msg.sender]) {
            revert IonicErrors.Unauthorized();
        }

        uint256 reason = _getMinterReason(msg.sender);

        _tokenCounter++;
        _safeMint(msg.sender, _tokenCounter);

        _tokens[_tokenCounter] = IonicLibrary.Token({
            minter: msg.sender,
            reason: reason
        });

        _authorizedMinters[msg.sender] = false;
        _removeMinterFromList(msg.sender);

        emit TokenMinted(msg.sender, _tokenCounter);
    }

    function _getMinterReason(address minter) private view returns (uint256) {
        for (uint256 i = 0; i < _mintersList.length; i++) {
            if (_mintersList[i].minter == minter) {
                return _mintersList[i].reason;
            }
        }
        return 0;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        uint256 reason = _tokens[tokenId].reason;

        return _tokenURIReason[reason];
    }

    function getMinters() public view returns (IonicLibrary.Minter[] memory) {
        return _mintersList;
    }

    function authorizeMinters(
        IonicLibrary.Minter[] calldata minters
    ) public onlyAdmin {
        for (uint256 i = 0; i < minters.length; i++) {
            if (!_authorizedMinters[minters[i].minter]) {
                _authorizedMinters[minters[i].minter] = true;
                _mintersList.push(minters[i]);
            }
        }
        emit MintersAuthorized(minters);
    }

    function _removeMinterFromList(address minter) private {
        for (uint256 i = 0; i < _mintersList.length; i++) {
            if (_mintersList[i].minter == minter) {
                _mintersList[i] = _mintersList[_mintersList.length - 1];
                _mintersList.pop();
                break;
            }
        }
    }

    function isAuthorizedMinter(address minter) external view returns (bool) {
        return _authorizedMinters[minter];
    }

    function updateTokenURI(
        uint256 reason,
        string memory uri
    ) public onlyAdmin {
        _tokenURIReason[reason] = uri;

        emit TokenURIUpdated(reason, uri);
    }

    function getToken(
        uint256 tokenId
    ) public view returns (IonicLibrary.Token memory) {
        return _tokens[tokenId];
    }

    function getTokenCounter() public view returns (uint256) {
        return _tokenCounter;
    }

    function setAccessControl(address _accessControl) external onlyAdmin {
        accessControl = IonicAccessControl(_accessControl);
    }
}
