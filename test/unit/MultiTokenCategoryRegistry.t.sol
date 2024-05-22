// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Test } from "forge-std/Test.sol";

import { MultiTokenCategoryRegistry, IMultiTokenCategoryRegistry } from "multitoken/MultiTokenCategoryRegistry.sol";


abstract contract MultiTokenCategoryRegistryTest is Test {

    bytes32 internal constant REGISTER_CATEGORY_SLOT = bytes32(uint256(2));

    address owner = makeAddr("owner");
    address assetAddress = makeAddr("assetAddress");

    MultiTokenCategoryRegistry registry;

    event CategoryRegistered(address indexed assetAddress, uint8 indexed category);
    event CategoryUnregistered(address indexed assetAddress);

    function setUp() external {
        vm.prank(owner);
        registry = new MultiTokenCategoryRegistry();
    }

}


/*----------------------------------------------------------*|
|*  # REGISTER CATEGORY VALUE                               *|
|*----------------------------------------------------------*/

contract MultiTokenCategoryRegistry_RegisterCategoryValue_Test is MultiTokenCategoryRegistryTest {

    function test_shouldFail_whenCallerNotOwner() external {
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        registry.registerCategoryValue(assetAddress, 7);
    }

    function test_shouldFail_whenCategoryMaxUint8Value() external {
        uint8 CATEGORY_NOT_REGISTERED = registry.CATEGORY_NOT_REGISTERED();

        vm.expectRevert(abi.encodeWithSelector(MultiTokenCategoryRegistry.ReservedCategoryValue.selector));
        vm.prank(owner);
        registry.registerCategoryValue(assetAddress, CATEGORY_NOT_REGISTERED);
    }

    function testFuzz_shouldStore_incrementedCategoryValue(address _assetAddress, uint8 category) external {
        vm.assume(category != type(uint8).max);

        vm.prank(owner);
        registry.registerCategoryValue(_assetAddress, category);

        bytes32 categorySlot = keccak256(abi.encode(_assetAddress, REGISTER_CATEGORY_SLOT));
        bytes32 categoryValue = vm.load(address(registry), categorySlot);
        assertEq(uint8(uint256(categoryValue)), category + 1);
    }

    function testFuzz_shouldEmit_CategoryRegistered(address _assetAddress, uint8 category) external {
        vm.assume(category != type(uint8).max);

        vm.expectEmit();
        emit CategoryRegistered(_assetAddress, category);

        vm.prank(owner);
        registry.registerCategoryValue(_assetAddress, category);
    }

}


/*----------------------------------------------------------*|
|*  # UNREGISTER CATEGORY VALUE                             *|
|*----------------------------------------------------------*/

contract MultiTokenCategoryRegistry_UnregisterCategoryValue_Test is MultiTokenCategoryRegistryTest {

    function test_shouldFail_whenCallerNotOwner() external {
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        registry.unregisterCategoryValue(assetAddress);
    }

    function testFuzz_shouldClearStore(address _assetAddress, uint256 storedCategory) external {
        vm.assume(storedCategory != 0 && storedCategory <= type(uint8).max);

        bytes32 categorySlot = keccak256(abi.encode(_assetAddress, REGISTER_CATEGORY_SLOT));
        vm.store(address(registry), categorySlot, bytes32(storedCategory));

        vm.prank(owner);
        registry.unregisterCategoryValue(_assetAddress);

        bytes32 categoryValue = vm.load(address(registry), categorySlot);
        assertEq(categoryValue, bytes32(0));
    }

    function testFuzz_shouldEmit_CategoryUnregistered(address _assetAddress) external {
        vm.expectEmit();
        emit CategoryUnregistered(_assetAddress);

        vm.prank(owner);
        registry.unregisterCategoryValue(_assetAddress);
    }

}


/*----------------------------------------------------------*|
|*  # REGISTERED CATEGORY VALUE                             *|
|*----------------------------------------------------------*/

contract MultiTokenCategoryRegistry_RegisteredCategoryValue_Test is MultiTokenCategoryRegistryTest {

    function testFuzz_shouldReturnCategoryValue_whenRegistered(uint256 storedCategory) external {
        vm.assume(storedCategory > 0 && storedCategory <= type(uint8).max);

        bytes32 categorySlot = keccak256(abi.encode(assetAddress, REGISTER_CATEGORY_SLOT));
        vm.store(address(registry), categorySlot, bytes32(storedCategory));

        uint8 category = registry.registeredCategoryValue(assetAddress);

        assertEq(category, storedCategory - 1);
    }

    function testFuzz_shouldReturnCategoryNotRegisteredValue_whenNotRegistered(address _assetAddress) external {
        uint8 category = registry.registeredCategoryValue(_assetAddress);

        assertEq(category, registry.CATEGORY_NOT_REGISTERED());
    }

}


/*----------------------------------------------------------*|
|*  # SUPPORTS INTERFACE                                    *|
|*----------------------------------------------------------*/

contract MultiTokenCategoryRegistry_SupportsInterface_Test is MultiTokenCategoryRegistryTest {

    function test_shouldReturnTrue_whenCategoryRegistryInterfaceId() external {
        bytes4 interfaceId = type(IMultiTokenCategoryRegistry).interfaceId;

        assertTrue(registry.supportsInterface(interfaceId));
    }

}
