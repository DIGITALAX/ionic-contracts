// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;

contract Errors {
    error Unauthorized();
    error AlreadyExists();
    error CantRemoveSelf();
    error NFTNotFound();
    error NFTNotActive();
    error AlreadyAppraised();
    error InvalidScore();
    error InvalidTokenType();
    error OnlySubmitter();
    error HolderNotFound();
    error InvalidTrustScore();
    error TrustNotFound();
    error NoInvitesAvailable();
    error DesignerNotFound();
    error DesignerNotActive();
    error OnlyInviter();
    error ReactionPackNotFound();
    error ReactionPackNotActive();
    error SoldOut();
    error InvalidPrice();
    error HolderSpotsOnly();
    error InsufficientBalance();
}