// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "@MT/MultiTokenCategoryRegistry.sol";


abstract contract MultiTokenCategoryRegistryTest is Test {

    address owner = makeAddr("owner");
    address assetAddress = makeAddr("assetAddress");

    MultiTokenCategoryRegistry registry;

    function setUp() external {
        vm.prank(owner);
        registry = new MultiTokenCategoryRegistry();
    }

}


/*----------------------------------------------------------*|
|*  # REGISTER CATEGORY                                     *|
|*----------------------------------------------------------*/

contract MultiTokenCategoryRegistry_RegisterCategory_Test is MultiTokenCategoryRegistryTest {

    function test_shouldFail_whenCallerNotOwner() external {
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        registry.registerCategory(assetAddress, 7);
    }

    function test_shouldFail_whenCategoryMaxUint8Value() external {
        uint8 CATEGORY_NOT_REGISTERED = registry.CATEGORY_NOT_REGISTERED();

        vm.expectRevert("MultiTokenCategoryRegistry: Reserved category value");
        vm.prank(owner);
        registry.registerCategory(assetAddress, CATEGORY_NOT_REGISTERED);
    }

    function test_shouldStore_incrementedCategoryValue(uint8 category) external {
        vm.assume(category >= 0 && category < type(uint8).max);

        vm.prank(owner);
        registry.registerCategory(assetAddress, category);

        bytes32 slot = keccak256(abi.encode(assetAddress, uint256(2)));
        bytes32 categoryValue = vm.load(address(registry), slot);
        assertEq(uint8(uint256(categoryValue)), category + 1);
    }

}


/*----------------------------------------------------------*|
|*  # UNREGISTER CATEGORY                                   *|
|*----------------------------------------------------------*/

contract MultiTokenCategoryRegistry_UnregisterCategory_Test is MultiTokenCategoryRegistryTest {

    function test_shouldFail_whenCallerNotOwner() external {
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        registry.unregisterCategory(assetAddress);
    }

    function testFuzz_shouldClearStore(uint256 storedCategory) external {
        vm.assume(storedCategory > 0 && storedCategory <= type(uint8).max);

        bytes32 slot = keccak256(abi.encode(assetAddress, uint256(2)));
        vm.store(address(registry), slot, bytes32(storedCategory));

        vm.prank(owner);
        registry.unregisterCategory(assetAddress);

        bytes32 categoryValue = vm.load(address(registry), slot);
        assertEq(categoryValue, bytes32(0));
    }

}


/*----------------------------------------------------------*|
|*  # REGISTERED CATEGORY                                   *|
|*----------------------------------------------------------*/

contract MultiTokenCategoryRegistry_RegisteredCategory_Test is MultiTokenCategoryRegistryTest {

    function testFuzz_shouldReturn_registeredCategory_whenRegistered(uint256 storedCategory) external {
        vm.assume(storedCategory > 0 && storedCategory <= type(uint8).max);

        bytes32 slot = keccak256(abi.encode(assetAddress, uint256(2)));
        vm.store(address(registry), slot, bytes32(storedCategory));

        uint8 category = registry.registeredCategory(assetAddress);

        assertEq(category, storedCategory - 1);
    }

    function test_shouldReturn_CATEGORY_NOT_REGISTERED_whenNotRegistered() external {
        uint8 category = registry.registeredCategory(assetAddress);

        assertEq(category, registry.CATEGORY_NOT_REGISTERED());
    }

}
