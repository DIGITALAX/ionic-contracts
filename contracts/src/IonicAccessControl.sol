// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;
import "./IonicErrors.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract IonicAccessControl {
    string public symbol;
    string public name;
    bool public adminControlRevoked;
    address public monaToken;
    address public ionicToken;

    mapping(address => bool) private _admins;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event AdminRevoked();
    event MonaTokenUpdated(address indexed newToken);
    event IonicTokenUpdated(address indexed newToken);

    modifier onlyAdmin() {
        if (adminControlRevoked) {
            revert IonicErrors.Unauthorized();
        }
        if (!_admins[msg.sender]) {
            revert IonicErrors.Unauthorized();
        }
        _;
    }

    constructor(address _monaToken) {
        _admins[msg.sender] = true;
        monaToken = _monaToken;
        symbol = "AC";
        name = "AccessControl";
    }

    function addAdmin(address admin) external onlyAdmin {
        if (_admins[admin]) {
            revert IonicErrors.AlreadyExists();
        }
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyAdmin {
        if (admin == msg.sender) {
            revert IonicErrors.CantRemoveSelf();
        }
        if (!_admins[admin]) {
            revert IonicErrors.Unauthorized();
        }
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function isConductor(address _address) public view returns (bool) {
        return ERC721(ionicToken).balanceOf(_address) >= 1;
    }

    function revokeAdminControl() external onlyAdmin {
        adminControlRevoked = true;
        emit AdminRevoked();
    }

    function setMonaToken(address _monaToken) external onlyAdmin {
        monaToken = _monaToken;
        emit MonaTokenUpdated(_monaToken);
    }

    function setIonicToken(address _ionicToken) external onlyAdmin {
        ionicToken = _ionicToken;
        emit IonicTokenUpdated(_ionicToken);
    }
}
