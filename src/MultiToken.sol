// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "./interfaces/ICryptoKitties.sol";


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
     *      If `_source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param _asset Struct defining all necessary context of a token.
     * @param _source Account/address that provided the allowance.
     * @param _dest Destination address.
     */
    function transferAssetFrom(Asset memory _asset, address _source, address _dest) internal {
        _transferAssetFrom(_asset, _source, _dest, false);
    }

    /**
     * safeTransferAssetFrom
     * @dev Wrapping function for `safeTransferFrom` calls on various token interfaces.
     *      If `_source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param _asset Struct defining all necessary context of a token.
     * @param _source Account/address that provided the allowance.
     * @param _dest Destination address.
     */
    function safeTransferAssetFrom(Asset memory _asset, address _source, address _dest) internal {
        _transferAssetFrom(_asset, _source, _dest, true);
    }

    function _transferAssetFrom(Asset memory _asset, address _source, address _dest, bool isSafe) private {
        if (_asset.category == Category.ERC20) {
            if (_source == address(this))
                require(IERC20(_asset.assetAddress).transfer(_dest, _asset.amount), "MultiToken: ERC20 transfer failed");
            else
                require(IERC20(_asset.assetAddress).transferFrom(_source, _dest, _asset.amount), "MultiToken: ERC20 transferFrom failed");

        } else if (_asset.category == Category.ERC721) {
            if (!isSafe)
                IERC721(_asset.assetAddress).transferFrom(_source, _dest, _asset.id);
            else
                IERC721(_asset.assetAddress).safeTransferFrom(_source, _dest, _asset.id, "");

        } else if (_asset.category == Category.ERC1155) {
            IERC1155(_asset.assetAddress).safeTransferFrom(_source, _dest, _asset.id, _asset.amount == 0 ? 1 : _asset.amount, "");

        } else if (_asset.category == Category.CryptoKitties) {
            ICryptoKitties(_asset.assetAddress).transferFrom(_source, _dest, _asset.id);

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
     * @param _asset Struct defining all necessary context of a token.
     * @param _source Account/address that provided the allowance.
     * @param _dest Destination address.
     */
    function transferAssetFromCalldata(Asset memory _asset, address _source, address _dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(_asset, _source, _dest, fromSender, false);
    }

    /**
     * safeTransferAssetFromCalldata
     * @dev Wrapping function for `safeTransferFrom` calladata on various token interfaces.
     *      If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param _asset Struct defining all necessary context of a token.
     * @param _source Account/address that provided the allowance.
     * @param _dest Destination address.
     */
    function safeTransferAssetFromCalldata(Asset memory _asset, address _source, address _dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(_asset, _source, _dest, fromSender, true);
    }

    function _transferAssetFromCalldata(Asset memory _asset, address _source, address _dest, bool fromSender, bool isSafe) pure private returns (bytes memory) {
        if (_asset.category == Category.ERC20) {
            if (fromSender) {
                return abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    _dest, _asset.amount
                );
            } else {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _source, _dest, _asset.amount
                );
            }
        } else if (_asset.category == Category.ERC721) {
            if (!isSafe) {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _source, _dest, _asset.id
                );
            } else {
                return abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,bytes)",
                    _source, _dest, _asset.id, ""
                );
            }

        } else if (_asset.category == Category.ERC1155) {
            return abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                _source, _dest, _asset.id, _asset.amount == 0 ? 1 : _asset.amount, ""
            );

        } else if (_asset.category == Category.CryptoKitties) {
            return abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                _source, _dest, _asset.id
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
     * @param _asset Struct defining all necessary context of a token.
     * @param _owner Account/address that signed the permit.
     * @param _spender Account/address that would be granted approval to `_asset`.
     * @param _permit Data about permit deadline (uint256) and permit signature (64/65 bytes).
     * Deadline and signature should be pack encoded together.
     * Signature can be standard (65 bytes) or compact (64 bytes) defined in EIP-2098.
     */
    function permit(Asset memory _asset, address _owner, address _spender, bytes memory _permit) internal {
        if (_asset.category == Category.ERC20) {

            // Parse deadline and permit signature parameters
            uint256 deadline;
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Parsing signature parameters used from OpenZeppelins ECDSA library
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/83277ff916ac4f58fec072b8f28a252c1245c2f1/contracts/utils/cryptography/ECDSA.sol

            // Deadline (32 bytes) + standard signature data (65 bytes) -> 97 bytes
            if (_permit.length == 97) {
                assembly {
                    deadline := mload(add(_permit, 0x20))
                    r := mload(add(_permit, 0x40))
                    s := mload(add(_permit, 0x60))
                    v := byte(0, mload(add(_permit, 0x80)))
                }
            }
            // Deadline (32 bytes) + compact signature data (64 bytes) -> 96 bytes
            else if (_permit.length == 96) {
                bytes32 vs;

                assembly {
                    deadline := mload(add(_permit, 0x20))
                    r := mload(add(_permit, 0x40))
                    vs := mload(add(_permit, 0x60))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert("MultiToken::Permit: Invalid permit length");
            }

            // Call permit with parsed parameters
            IERC20Permit(_asset.assetAddress).permit(_owner, _spender, _asset.amount, deadline, v, r, s);

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
     * @param _asset Struct defining all necessary context of a token.
     * @param _target Target address to be checked.
     */
    function balanceOf(Asset memory _asset, address _target) internal view returns (uint256) {
        if (_asset.category == Category.ERC20) {
            return IERC20(_asset.assetAddress).balanceOf(_target);

        } else if (_asset.category == Category.ERC721) {
            return IERC721(_asset.assetAddress).ownerOf(_asset.id) == _target ? 1 : 0;

        } else if (_asset.category == Category.ERC1155) {
            return IERC1155(_asset.assetAddress).balanceOf(_target, _asset.id);

        } else if (_asset.category == Category.CryptoKitties) {
            return ICryptoKitties(_asset.assetAddress).ownerOf(_asset.id) == _target ? 1 : 0;

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # APPROVE ASSET                                         *|
    |*----------------------------------------------------------*/

    /**
     * approveAsset
     * @dev Wrapping function for approve calls on various token interfaces.
     * @param _asset Struct defining all necessary context of a token.
     * @param _target Account/address that would be granted approval to `_asset`.
     */
    function approveAsset(Asset memory _asset, address _target) internal {
        if (_asset.category == Category.ERC20) {
            IERC20(_asset.assetAddress).approve(_target, _asset.amount);

        } else if (_asset.category == Category.ERC721) {
            IERC721(_asset.assetAddress).approve(_target, _asset.id);

        } else if (_asset.category == Category.ERC1155) {
            IERC1155(_asset.assetAddress).setApprovalForAll(_target, true);

        } else if (_asset.category == Category.CryptoKitties) {
            ICryptoKitties(_asset.assetAddress).approve(_target, _asset.id);

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
     * @param _asset Asset that is examined.
     * @return True if assets amount and id is valid in stated category.
     */
    function isValid(Asset memory _asset) internal pure returns (bool) {
        // ERC20 token has to have id set to 0
        if (_asset.category == Category.ERC20 && _asset.id != 0)
            return false;

        // ERC721 token has to have amount set to 1
        if ((_asset.category == Category.ERC721 || _asset.category == Category.CryptoKitties) && _asset.amount != 1)
            return false;

        // Any categories have to have non-zero amount
        if (_asset.amount == 0)
            return false;

        return true;
    }

    /**
     * isSameAs
     * @dev Compare two assets, ignoring their amounts.
     * @param _asset First asset to examine.
     * @param _otherAsset Second asset to examine.
     * @return True if both structs represents the same asset.
     */
    function isSameAs(Asset memory _asset, Asset memory _otherAsset) internal pure returns (bool) {
        return
            _asset.category == _otherAsset.category &&
            _asset.assetAddress == _otherAsset.assetAddress &&
            _asset.id == _otherAsset.id;
    }
}
