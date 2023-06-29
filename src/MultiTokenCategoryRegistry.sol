// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/access/Ownable2Step.sol";


contract MultiTokenCategoryRegistry is Ownable2Step {

    uint8 public constant CATEGORY_NOT_REGISTERED = type(uint8).max;

    /**
     * @dev Mapping of assets address to its known category (asset address -> MultiToken Category raw value).
     *      Categories are incremented by one before being stored to distinguish between 0 category value and category not registered.
     */
    mapping (address => uint8) private _registeredCategory;


    /**
     * registerCategory
     * @dev Register a MultiToken Category to an asset address.
     * @param assetAddress Address of an asset to which category is registered.
     * @param category A raw value of a MultiToken Category to register for an asset.
     */
    function registerCategory(address assetAddress, uint8 category) external onlyOwner {
        require(category != CATEGORY_NOT_REGISTERED, "MultiTokenCategoryRegistry: Reserved category value");

        _registeredCategory[assetAddress] = category + 1;
    }

    /**
     * unregisterCategory
     * @dev Clear the stored category for the asset address.
     * @param assetAddress Address of an asset to which category is unregistered.
     */
    function unregisterCategory(address assetAddress) external onlyOwner {
        delete _registeredCategory[assetAddress];
    }

    /**
     * registeredCategory
     * @dev Getter for a registered category of a given asset address.
     * @param assetAddress Address of an asset to which category is requested.
     * @return Category value registered for the asset address.
     */
    function registeredCategory(address assetAddress) external view returns (uint8) {
        uint8 category = _registeredCategory[assetAddress];
        return category == 0 ? CATEGORY_NOT_REGISTERED : category - 1;
    }

}
