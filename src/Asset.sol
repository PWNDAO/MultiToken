// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Category
 * @dev Enum representation Asset category.
 */
enum Category {
    ERC20,
    ERC721,
    ERC1155,
    CryptoKitties
}

/**
 * @title Asset
 * @param category Corresponding asset category.
 * @param assetAddress Address of the token contract defining the asset.
 * @param id TokenID of an NFT or 0.
 * @param amount Amount of fungible tokens or 0 -> 1.
 */
struct Asset {
    Category category;
    address assetAddress;
    uint256 id;
    uint256 amount;
}
