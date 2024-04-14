// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { ERC165 } from "openzeppelin/utils/introspection/ERC165.sol";

import { IMultiTokenCategoryRegistry } from "src/interfaces/IMultiTokenCategoryRegistry.sol";

/**
 * @title MultiToken Category Registry
 * @notice Contract to register known MultiToken Categories for assets.
 * @dev Categories are stored as incremented by one to distinguish between 0 category value and category not registered.
 */
contract MultiTokenCategoryRegistry is Ownable2Step, ERC165, IMultiTokenCategoryRegistry {

    /**
    * @notice A reserved value for a category not registered.
    */
    uint8 public constant CATEGORY_NOT_REGISTERED = type(uint8).max;

    /**
     * @notice Mapping of assets address to its known category.
     * @dev Categories are incremented by one before being stored to distinguish between 0 category value and category not registered.
     */
    mapping (address => uint8) private _registeredCategory;

    /**
    * @notice Thrown when a reserved category value is used to register a category.
    */
    error ReservedCategoryValue();

    /**
     * @inheritdoc IMultiTokenCategoryRegistry
     */
    function registerCategoryValue(address assetAddress, uint8 category) external onlyOwner {
        if (category == CATEGORY_NOT_REGISTERED)
            revert ReservedCategoryValue(); // Note: to unregister a category, use `unregisterCategory` method.

        _registeredCategory[assetAddress] = category + 1;

        emit CategoryRegistered(assetAddress, category);
    }

    /**
     * @inheritdoc IMultiTokenCategoryRegistry
     */
    function unregisterCategoryValue(address assetAddress) external onlyOwner {
        delete _registeredCategory[assetAddress];

        emit CategoryUnregistered(assetAddress);
    }

    /**
     * @inheritdoc IMultiTokenCategoryRegistry
     */
    function registeredCategoryValue(address assetAddress) external view returns (uint8) {
        uint8 category = _registeredCategory[assetAddress];
        return category == 0 ? CATEGORY_NOT_REGISTERED : category - 1;
    }

    /**
     * @notice Check if the contract supports an interface.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return `true` if the contract supports `interfaceId`, `false` otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IMultiTokenCategoryRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
