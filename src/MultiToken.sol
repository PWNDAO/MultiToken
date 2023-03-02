// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/interfaces/IERC20.sol";
import "@openzeppelin/interfaces/IERC721.sol";
import "@openzeppelin/interfaces/IERC1155.sol";
import "@openzeppelin/token/ERC20/extensions/draft-IERC20Permit.sol";

import "@MT/interfaces/ICryptoKitties.sol";


library MultiToken {

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


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET                                        *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetFrom
     * @dev Wrapping function for `transferFrom` calls on various token interfaces.
     *      If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, false);
    }

    /**
     * safeTransferAssetFrom
     * @dev Wrapping function for `safeTransferFrom` calls on various token interfaces.
     *      If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, true);
    }

    function _transferAssetFrom(Asset memory asset, address source, address dest, bool isSafe) private {
        if (asset.category == Category.ERC20) {
            if (source == address(this))
                require(IERC20(asset.assetAddress).transfer(dest, asset.amount), "MultiToken: ERC20 transfer failed");
            else
                require(IERC20(asset.assetAddress).transferFrom(source, dest, asset.amount), "MultiToken: ERC20 transferFrom failed");

        } else if (asset.category == Category.ERC721) {
            if (!isSafe)
                IERC721(asset.assetAddress).transferFrom(source, dest, asset.id);
            else
                IERC721(asset.assetAddress).safeTransferFrom(source, dest, asset.id, "");

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).safeTransferFrom(source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, "");

        } else if (asset.category == Category.CryptoKitties) {
            ICryptoKitties(asset.assetAddress).transferFrom(source, dest, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET CALLDATA                               *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetFromCalldata
     * @dev Wrapping function for `transferFrom` calladata on various token interfaces.
     *      If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, false);
    }

    /**
     * safeTransferAssetFromCalldata
     * @dev Wrapping function for `safeTransferFrom` calladata on various token interfaces.
     *      If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, true);
    }

    function _transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender, bool isSafe) pure private returns (bytes memory) {
        if (asset.category == Category.ERC20) {
            if (fromSender) {
                return abi.encodeWithSignature(
                    "transfer(address,uint256)", dest, asset.amount
                );
            } else {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.amount
                );
            }
        } else if (asset.category == Category.ERC721) {
            if (!isSafe) {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.id
                );
            } else {
                return abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,bytes)", source, dest, asset.id, ""
                );
            }

        } else if (asset.category == Category.ERC1155) {
            return abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)", source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, ""
            );

        } else if (asset.category == Category.CryptoKitties) {
            return abi.encodeWithSignature(
                "transferFrom(address,address,uint256)", source, dest, asset.id
            );

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # PERMIT                                                *|
    |*----------------------------------------------------------*/

    /**
     * permit
     * @dev Wrapping function for granting approval via permit signature.
     * @param asset Struct defining all necessary context of a token.
     * @param owner Account/address that signed the permit.
     * @param spender Account/address that would be granted approval to `asset`.
     * @param permitData Data about permit deadline (uint256) and permit signature (64/65 bytes).
     *                   Deadline and signature should be pack encoded together.
     *                   Signature can be standard (65 bytes) or compact (64 bytes) defined in EIP-2098.
     */
    function permit(Asset memory asset, address owner, address spender, bytes memory permitData) internal {
        if (asset.category == Category.ERC20) {

            // Parse deadline and permit signature parameters
            uint256 deadline;
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Parsing signature parameters used from OpenZeppelins ECDSA library
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/83277ff916ac4f58fec072b8f28a252c1245c2f1/contracts/utils/cryptography/ECDSA.sol

            // Deadline (32 bytes) + standard signature data (65 bytes) -> 97 bytes
            if (permitData.length == 97) {
                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    s := mload(add(permitData, 0x60))
                    v := byte(0, mload(add(permitData, 0x80)))
                }
            }
            // Deadline (32 bytes) + compact signature data (64 bytes) -> 96 bytes
            else if (permitData.length == 96) {
                bytes32 vs;

                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    vs := mload(add(permitData, 0x60))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert("MultiToken::Permit: Invalid permit length");
            }

            // Call permit with parsed parameters
            IERC20Permit(asset.assetAddress).permit(owner, spender, asset.amount, deadline, v, r, s);

        } else {
            // Currently supporting only ERC20 signed approvals via ERC2612
            revert("MultiToken::Permit: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # BALANCE OF                                            *|
    |*----------------------------------------------------------*/

    /**
     * balanceOf
     * @dev Wrapping function for checking balances on various token interfaces.
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
    |*  # APPROVE ASSET                                         *|
    |*----------------------------------------------------------*/

    /**
     * approveAsset
     * @dev Wrapping function for `approve` calls on various token interfaces.
     * @param asset Struct defining all necessary context of a token.
     * @param target Account/address that would be granted approval to `asset`.
     */
    function approveAsset(Asset memory asset, address target) internal {
        if (asset.category == Category.ERC20) {
            IERC20(asset.assetAddress).approve(target, asset.amount);

        } else if (asset.category == Category.ERC721) {
            IERC721(asset.assetAddress).approve(target, asset.id);

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).setApprovalForAll(target, true);

        } else if (asset.category == Category.CryptoKitties) {
            ICryptoKitties(asset.assetAddress).approve(target, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # ASSET CHECKS                                          *|
    |*----------------------------------------------------------*/

    /**
     * isValid
     * @dev Checks that assets amount and id is valid in stated category.
     *      This function don't check that stated category is indeed the category of a contract on a stated address.
     * @param asset Asset that is examined.
     * @return True if assets amount and id is valid in stated category.
     */
    function isValid(Asset memory asset) internal pure returns (bool) {
        // ERC20 token has to have id set to 0
        if (asset.category == Category.ERC20 && asset.id != 0)
            return false;

        // ERC721 & CryptoKitties token has to have amount set to 0
        if ((asset.category == Category.ERC721 || asset.category == Category.CryptoKitties) && asset.amount != 0)
            return false;

        return true;
    }

    /**
     * isSameAs
     * @dev Compare two assets, ignoring their amounts.
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
