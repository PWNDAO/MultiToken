// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title MultiToken Category Registry Interface
* @notice Interface for the MultiToken Category Registry.
* @dev Category Registry Interface ID is 0xc37a4a01.
*/
interface IMultiTokenCategoryRegistry {

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
     * @notice Register a MultiToken Category value to an asset address.
     * @param assetAddress Address of an asset to which category is registered.
     * @param category A raw value of a MultiToken Category to register for an asset.
     */
    function registerCategoryValue(address assetAddress, uint8 category) external;

    /**
     * @notice Clear the stored category for the asset address.
     * @param assetAddress Address of an asset to which category is unregistered.
     */
    function unregisterCategoryValue(address assetAddress) external;

    /**
     * @notice Getter for a registered category value of a given asset address.
     * @param assetAddress Address of an asset to which category is requested.
     * @return Raw category value registered for the asset address.
     */
    function registeredCategoryValue(address assetAddress) external view returns (uint8);

}
