// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable2Step } from "@openzeppelin/access/Ownable2Step.sol";
import { ERC165 } from "@openzeppelin/utils/introspection/ERC165.sol";


/**
 * @title MultiToken Category Registry
 * @notice Contract to register known MultiToken Categories for assets.
 * @dev Categories are stored as incremented by one to distinguish between 0 category value and category not registered.
 */
contract MultiTokenCategoryRegistry is Ownable2Step, ERC165 {

    /**
    * @notice A reserved value for a category not registered.
    */
    uint8 public constant CATEGORY_NOT_REGISTERED = type(uint8).max;

    /**
    * @notice Interface ID for the MultiToken Category Registry.
    * @dev Category Registry Interface ID is 0xc37a4a01.
    */
    bytes4 public constant CATEGORY_REGISTRY_INTERFACE_ID =
        this.registerCategory.selector ^
        this.unregisterCategory.selector ^
        this.registeredCategory.selector;

    /**
     * @notice Mapping of assets address to its known category.
     * @dev Categories are incremented by one before being stored to distinguish between 0 category value and category not registered.
     */
    mapping (address => uint8) private _registeredCategory;

    /**
    * @notice Emitted when a category is registered for an asset address.
    * @param assetAddress Address of an asset to which category is registered.
    * @param category A raw value of a MultiToken Category registered for an asset.
    */
    event CategoryRegistered(address indexed assetAddress, uint8 indexed category);

    /**
    * @notice Emitted when a category is unregistered for an asset address.
    * @param assetAddress Address of an asset to which category is unregistered.
    */
    event CategoryUnregistered(address indexed assetAddress);

    /**
    * @notice Thrown when a reserved category value is used to register a category.
    */
    error ReservedCategoryValue();

    /**
     * @notice Register a MultiToken Category to an asset address.
     * @param assetAddress Address of an asset to which category is registered.
     * @param category A raw value of a MultiToken Category to register for an asset.
     */
    function registerCategory(address assetAddress, uint8 category) external onlyOwner {
        if (category == CATEGORY_NOT_REGISTERED)
            revert ReservedCategoryValue(); // Note: to unregister a category, use `unregisterCategory` method.

        _registeredCategory[assetAddress] = category + 1;

        emit CategoryRegistered(assetAddress, category);
    }

    /**
     * @notice Clear the stored category for the asset address.
     * @param assetAddress Address of an asset to which category is unregistered.
     */
    function unregisterCategory(address assetAddress) external onlyOwner {
        delete _registeredCategory[assetAddress];

        emit CategoryUnregistered(assetAddress);
    }

    /**
     * @notice Getter for a registered category of a given asset address.
     * @param assetAddress Address of an asset to which category is requested.
     * @return Category value registered for the asset address.
     */
    function registeredCategory(address assetAddress) external view returns (uint8) {
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
            interfaceId == CATEGORY_REGISTRY_INTERFACE_ID ||
            super.supportsInterface(interfaceId);
    }

}
