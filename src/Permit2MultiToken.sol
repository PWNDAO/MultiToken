// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";
import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC1155 } from "openzeppelin/interfaces/IERC1155.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ERC165Checker } from "openzeppelin/utils/introspection/ERC165Checker.sol";
import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";

import { ICryptoKitties } from "multitoken/interfaces/ICryptoKitties.sol";
import { IMultiTokenCategoryRegistry } from "multitoken/interfaces/IMultiTokenCategoryRegistry.sol";
import { IPermit2Like } from "multitoken/interfaces/IPermit2Like.sol";

import { Asset, Category } from "multitoken/Asset.sol";

/**
 * @title Permit2 MultiToken library
 * @dev Library for handling various token standards (ERC20, ERC721, ERC1155, CryptoKitties) in a single contract via Permit2.
 */
library Permit2MultiToken {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    bytes4 public constant ERC20_INTERFACE_ID = 0x36372b07;
    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 public constant ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 public constant CRYPTO_KITTIES_INTERFACE_ID = 0x9a20483d;

    /**
    * @notice A reserved value for a category not registered.
    */
    uint8 public constant CATEGORY_NOT_REGISTERED = type(uint8).max;

    /**
     * @notice Thrown when unsupported category is used.
     * @param categoryValue Value of the unsupported category.
     */
    error UnsupportedCategory(uint8 categoryValue);

    /*----------------------------------------------------------*|
    |*  # FACTORY FUNCTIONS                                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice Factory function for creating an ERC20 asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param amount Amount of fungible tokens.
     * @return Asset struct representing the ERC20 asset.
     */
    function ERC20(address assetAddress, uint256 amount) internal pure returns (Asset memory) {
        return Asset(Category.ERC20, assetAddress, 0, amount);
    }

    /**
     * @notice Factory function for creating an ERC721 asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of an NFT.
     * @return Asset struct representing the ERC721 asset.
     */
    function ERC721(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.ERC721, assetAddress, id, 0);
    }

    /**
     * @notice Factory function for creating an ERC1155 asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of an SFT.
     * @param amount Amount of semifungible tokens.
     * @return Asset struct representing the ERC1155 asset.
     */
    function ERC1155(address assetAddress, uint256 id, uint256 amount) internal pure returns (Asset memory) {
        return Asset(Category.ERC1155, assetAddress, id, amount);
    }

    /**
     * @notice Factory function for creating an ERC1155 NFT asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of an NFT.
     * @return Asset struct representing the ERC1155 NFT asset.
     */
    function ERC1155(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.ERC1155, assetAddress, id, 0);
    }

    /**
     * @notice Factory function for creating a CryptoKitties asset.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id Token id of a CryptoKitty.
     * @return Asset struct representing the CryptoKitties asset.
     */
    function CryptoKitties(address assetAddress, uint256 id) internal pure returns (Asset memory) {
        return Asset(Category.CryptoKitties, assetAddress, id, 0);
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Wrapping function for `transferFrom` calls.
     * @dev If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param permit2 Address of the Permit2 contract to be used for transferring ERC20 tokens.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFrom(Asset memory asset, address permit2, address source, address dest) internal {
        if (asset.category != Category.ERC20) {
            revert("MultiToken: Unsupported category");
        }

        if (source == address(this)) {
            IERC20(asset.assetAddress).safeTransfer(dest, asset.amount);
        } else {
            IPermit2Like(permit2).transferFrom(source, dest, asset.amount.toUint160(), asset.assetAddress);
        }
    }

    /**
     * @notice Wrapping function for `transferFrom` calls.
     * @dev If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param permit2 Address of the Permit2 contract to be used for transferring ERC20 tokens.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     * @param permit PermitTransferFrom struct containing the signed permit data.
     * @param signature Signature to verify the permit.
     */
    function permitTransferAssetFrom(
        Asset memory asset,
        address permit2,
        address source,
        address dest,
        IPermit2Like.PermitTransferFrom memory permit,
        bytes memory signature
    ) internal {
        if (asset.category != Category.ERC20) {
            revert("MultiToken: Unsupported category");
        }

        if (source == address(this)) {
            IERC20(asset.assetAddress).safeTransfer(dest, asset.amount);
        } else {
            IPermit2Like(permit2).permitTransferFrom(
                permit, IPermit2Like.SignatureTransferDetails(dest, asset.amount), source, signature
            );
        }
    }

    /**
     * @notice Get amount of asset that would be transferred.
     * @dev NFTs (ERC721, CryptoKitties & ERC1155 with amount 0) with return 1.
     *      Fungible tokens will return its amount (ERC20 with 0 amount is valid).
     *      In combination with `balanceOf` can be used to check successful asset transfer.
     * @param asset Struct defining all necessary context of a token.
     * @return Number of tokens that would be transferred of the asset.
     */
    function getTransferAmount(Asset memory asset) internal pure returns (uint256) {
        if (asset.category == Category.ERC20)
            return asset.amount;
        else if (asset.category == Category.ERC1155 && asset.amount > 0)
            return asset.amount;
        else // Return 1 for ERC721, CryptoKitties and ERC1155 used as NFTs (amount = 0)
            return 1;
    }


    /*----------------------------------------------------------*|
    |*  # BALANCE OF                                            *|
    |*----------------------------------------------------------*/

    /**
     * @notice Wrapping function for checking balances on various token interfaces.
     * @param asset Struct defining all necessary context of a token.
     * @param target Target address to be checked.
     */
    function balanceOf(Asset memory asset, address target) internal view returns (uint256) {
        if (asset.category == Category.ERC20) {
            return IERC20(asset.assetAddress).balanceOf(target);

        } else if (asset.category == Category.ERC721) {
            return IERC721(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else if (asset.category == Category.ERC1155) {
            return IERC1155(asset.assetAddress).balanceOf(target, asset.id);

        } else if (asset.category == Category.CryptoKitties) {
            return ICryptoKitties(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # ASSET CHECKS                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Checks that provided asset is contract, has correct format and stated category via MultiTokenCategoryRegistry and ERC165 checks.
     * @dev Fungible tokens (ERC20) have to have id = 0.
     *      NFT (ERC721, CryptoKitties) tokens have to have amount = 0.
     *      Correct asset category is determined via ERC165.
     *      The check assumes, that asset contract implements only one token standard at a time.
     * @param registry Category registry contract.
     * @param asset Asset that is examined.
     * @return True if asset has correct format and category.
     */
    function isValid(Asset memory asset, IMultiTokenCategoryRegistry registry) internal view returns (bool) {
        return _checkCategory(asset, registry) && _checkFormat(asset);
    }

    /**
     * @notice Checks that provided asset is contract, has correct format and stated category via ERC165 checks.
     * @dev Fungible tokens (ERC20) have to have id = 0.
     *      NFT (ERC721, CryptoKitties) tokens have to have amount = 0.
     *      Correct asset category is determined via ERC165.
     *      The check assumes, that asset contract implements only one token standard at a time.
     * @param asset Asset that is examined.
     * @return True if asset has correct format and category.
     */
    function isValid(Asset memory asset) internal view returns (bool) {
        return _checkCategoryViaERC165(asset) && _checkFormat(asset);
    }

    /**
     * @notice Checks that provided asset is contract and stated category is correct via MultiTokenCategoryRegistry and ERC165 checks.
     * @dev Will fallback to ERC165 checks if asset is not registered in the category registry.
     *      The check assumes, that asset contract implements only one token standard at a time.
     * @param registry Category registry contract.
     * @param asset Asset that is examined.
     * @return True if assets stated category is correct.
     */
    function _checkCategory(Asset memory asset, IMultiTokenCategoryRegistry registry) internal view returns (bool) {
        // Check if asset is registered in the category registry
        uint8 categoryValue = registry.registeredCategoryValue(asset.assetAddress);
        if (categoryValue != CATEGORY_NOT_REGISTERED)
            return uint8(asset.category) == categoryValue;

        return _checkCategoryViaERC165(asset);
    }

    /**
     * @notice Checks that provided asset is contract and stated category is correct via ERC165 checks.
     * @dev The check assumes, that asset contract implements only one token standard at a time.
     * @param asset Asset that is examined.
     * @return True if assets stated category is correct.
     */
    function _checkCategoryViaERC165(Asset memory asset) internal view returns (bool) {
        if (asset.category == Category.ERC20) {
            // ERC20 has optional ERC165 implementation
            if (asset.assetAddress.supportsERC165()) {
                // If contract implements ERC165 and returns true for ERC20 intefrace id, consider it a correct category
                if (asset.assetAddress.supportsERC165InterfaceUnchecked(ERC20_INTERFACE_ID))
                    return true;

                // If contract implements ERC165, it has to return false for ERC721, ERC1155, and CryptoKitties interface ids
                return
                    !asset.assetAddress.supportsERC165InterfaceUnchecked(ERC721_INTERFACE_ID) &&
                    !asset.assetAddress.supportsERC165InterfaceUnchecked(ERC1155_INTERFACE_ID) &&
                    !asset.assetAddress.supportsERC165InterfaceUnchecked(CRYPTO_KITTIES_INTERFACE_ID);

            } else {
                // In case token doesn't implement ERC165, its safe to assume that provided category is correct,
                // because any other category has to implement ERC165.

                // Check that asset address is contract
                // Note: Asset address will return code length 0, if this code is called from the constructor.
                return asset.assetAddress.code.length > 0;
            }

        } else if (asset.category == Category.ERC721) {
            // Check ERC721 via ERC165
            return asset.assetAddress.supportsInterface(ERC721_INTERFACE_ID);

        } else if (asset.category == Category.ERC1155) {
            // Check ERC1155 via ERC165
            return asset.assetAddress.supportsInterface(ERC1155_INTERFACE_ID);

        } else if (asset.category == Category.CryptoKitties) {
            // Check CryptoKitties via ERC165
            return asset.assetAddress.supportsInterface(CRYPTO_KITTIES_INTERFACE_ID);

        } else {
            revert UnsupportedCategory(uint8(asset.category));
        }
    }

    /**
     * @notice Checks that provided asset has correct format.
     * @dev Fungible tokens (ERC20) have to have id = 0.
     *      NFT (ERC721, CryptoKitties) tokens have to have amount = 0.
     *      Correct asset category is determined via ERC165.
     * @param asset Asset that is examined.
     * @return True asset struct has correct format.
     */
    function _checkFormat(Asset memory asset) internal pure returns (bool) {
        if (asset.category == Category.ERC20) {
            // Id must be 0 for ERC20
            if (asset.id != 0) return false;

        } else if (asset.category == Category.ERC721) {
            // Amount must be 0 for ERC721
            if (asset.amount != 0) return false;

        } else if (asset.category == Category.ERC1155) {
            // No format check for ERC1155

        } else if (asset.category == Category.CryptoKitties) {
            // Amount must be 0 for CryptoKitties
            if (asset.amount != 0) return false;

        } else {
            revert UnsupportedCategory(uint8(asset.category));
        }

        return true;
    }

    /**
     * @notice Compare two assets, ignoring their amounts.
     * @param asset First asset to examine.
     * @param otherAsset Second asset to examine.
     * @return True if both structs represents the same asset.
     */
    function isSameAs(Asset memory asset, Asset memory otherAsset) internal pure returns (bool) {
        return
            asset.category == otherAsset.category &&
            asset.assetAddress == otherAsset.assetAddress &&
            asset.id == otherAsset.id;
    }

}
