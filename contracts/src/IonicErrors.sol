// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.28;

contract IonicErrors {
    error Unauthorized();
    error AlreadyExists();
    error CantRemoveSelf();
    error NFTNotFound();
    error NFTNotActive();
    error AlreadyAppraised();
    error InvalidScore();
    error InvalidTokenType();
    error OnlySubmitter();
    error ConductorNotFound();
    error InvalidReviewScore();
    error ReviewNotFound();
    error NoInvitesAvailable();
    error DesignerNotFound();
    error DesignerNotActive();
    error OnlyInviter();
    error ReactionPackNotFound();
    error ReactionPackNotActive();
    error SoldOut();
    error InvalidPrice();
    error ConductorSpotsOnly();
    error InsufficientBalance();
    error InvalidInput();
}