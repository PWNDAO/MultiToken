// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Test } from "forge-std/Test.sol";

import {
    Permit2MultiToken, IMultiTokenCategoryRegistry, Asset, Category,
    IERC20, IPermit2Like, IERC721, IERC1155, ICryptoKitties
} from "multitoken/Permit2MultiToken.sol";

import { Permit2MultiTokenHarness } from "test/harness/Permit2MultiTokenHarness.sol";

using Permit2MultiToken for address;
using Permit2MultiToken for Asset;

abstract contract Permit2MultiTokenTest is Test {

    address token = address(0xa66e7);
    address source = address(0xa11ce);
    address recipient = address(0xb0b);
    address permit2 = makeAddr("permit2");
    uint256 id = 373733;
    uint256 amount = 101e18;

    Asset asset;
    IMultiTokenCategoryRegistry registry = IMultiTokenCategoryRegistry(makeAddr("registry"));
    Permit2MultiTokenHarness harness = new Permit2MultiTokenHarness();

    constructor() {
        vm.etch(token, bytes("0x01"));
    }

    function _mockERC165Support(address _token, bytes4 interfaceId, bool support) internal {
        vm.mockCall(
            _token,
            abi.encodeWithSignature("supportsInterface(bytes4)", bytes4(0x01ffc9a7)), // InterfaceId_ERC165
            abi.encode(true)
        );
        vm.mockCall(
            _token,
            abi.encodeWithSignature("supportsInterface(bytes4)", bytes4(0xffffffff)), // InterfaceId_Invalid
            abi.encode(false)
        );
        vm.mockCall(
            _token,
            abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId),
            abi.encode(support)
        );
    }

    function _mockRegistryCategory(uint8 _category) internal {
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(IMultiTokenCategoryRegistry.registeredCategoryValue.selector, token),
            abi.encode(_category)
        );
    }

}


/*----------------------------------------------------------*|
|*  # FACTORY FUNCTIONS                                     *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_FactoryFunctions_Test is Permit2MultiTokenTest {

    function testFuzz_shouldReturnERC20(address assetAddress, uint256 _amount) external {
        Asset memory asset = Permit2MultiToken.ERC20(assetAddress, _amount);

        assertTrue(asset.category == Category.ERC20);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, 0);
        assertEq(asset.amount, _amount);
    }

    function test_shouldReturnERC721(address assetAddress, uint256 _id) external {
        Asset memory asset = Permit2MultiToken.ERC721(assetAddress, _id);

        assertTrue(asset.category == Category.ERC721);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, 0);
    }

    function test_shouldReturnERC1155_withZeroAmount(address assetAddress, uint256 _id) external {
        Asset memory asset = Permit2MultiToken.ERC1155(assetAddress, _id);

        assertTrue(asset.category == Category.ERC1155);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, 0);
    }

    function test_shouldReturnERC1155(address assetAddress, uint256 _id, uint256 _amount) external {
        Asset memory asset = Permit2MultiToken.ERC1155(assetAddress, _id, _amount);

        assertTrue(asset.category == Category.ERC1155);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, _amount);
    }

    function test_shouldReturnCryptoKitties(address assetAddress, uint256 _id) external {
        Asset memory asset = Permit2MultiToken.CryptoKitties(assetAddress, _id);

        assertTrue(asset.category == Category.CryptoKitties);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, 0);
    }

}


/*----------------------------------------------------------*|
|*  # TRANSFER ASSET FROM                                   *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_TransferAssetFrom_Test is Permit2MultiTokenTest {

    function setUp() external {
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)"),
            abi.encode(true)
        );
        vm.mockCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)"),
            abi.encode(true)
        );
        vm.mockCall(
            permit2,
            abi.encodeWithSignature("transferFrom(address,address,uint160,address)"),
            abi.encode("")
        );
    }


    // ERC20

    function test_shouldCallTransfer_whenERC20_whenSourceIsThis() external {
        vm.expectCall(token, abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));

        harness.transferAssetFrom(token.ERC20(amount), permit2, address(harness), recipient);
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenTransferReturnsFalse() external {
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            abi.encode(false)
        );

        vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
        harness.transferAssetFrom(token.ERC20(amount), permit2, address(harness), recipient);
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        vm.expectRevert("Address: call to non-contract");
        harness.transferAssetFrom(nonContractAddress.ERC20(amount), permit2, address(harness), recipient);
    }

    function test_shouldCallTransferFrom_whenERC20_whenSourceIsNotThis() external {
        vm.expectCall(
            permit2,
            abi.encodeWithSignature("transferFrom(address,address,uint160,address)", source, recipient, amount, token)
        );
        harness.transferAssetFrom(token.ERC20(amount), permit2, source, recipient);
    }

    function test_shouldFail_whenERC20_whenSourceIsNotThis_whenTransferReverts() external {
        vm.mockCallRevert(
            permit2,
            abi.encodeWithSignature("transferFrom(address,address,uint160,address)", source, recipient, amount, token),
            abi.encode("revert data")
        );

        vm.expectRevert("revert data");
        harness.transferAssetFrom(token.ERC20(amount), permit2, source, recipient);
    }

    // ERC721

    function test_shouldFail_forUnsupportedCategory() external {
        Asset memory asset = Asset(Category.ERC20, token, id, amount);

        asset.category = Category.ERC721;
        vm.expectRevert("MultiToken: Unsupported category");
        harness.transferAssetFrom(asset, permit2, source, recipient);

        asset.category = Category.ERC1155;
        vm.expectRevert("MultiToken: Unsupported category");
        harness.transferAssetFrom(asset, permit2, source, recipient);

        asset.category = Category.CryptoKitties;
        vm.expectRevert("MultiToken: Unsupported category");
        harness.transferAssetFrom(asset, permit2, source, recipient);
    }

}


/*----------------------------------------------------------*|
|*  # PERMIT TRANSFER ASSET FROM                            *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_PermitTransferAssetFrom_Test is Permit2MultiTokenTest {

    IPermit2Like.PermitTransferFrom permit;
    bytes signature;

    function setUp() external {
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)"),
            abi.encode(true)
        );
        vm.mockCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)"),
            abi.encode(true)
        );
        vm.mockCall(
            permit2,
            abi.encodeWithSignature("transferFrom(address,address,uint160,address)"),
            abi.encode("")
        );

        permit = IPermit2Like.PermitTransferFrom({
            permitted: IPermit2Like.TokenPermissions(token, amount),
            nonce: 0,
            deadline: type(uint256).max
        });
        signature = "signature";
    }


    // ERC20

    function test_shouldCallTransfer_whenERC20_whenSourceIsThis() external {
        vm.expectCall(token, abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));

        harness.permitTransferAssetFrom(token.ERC20(amount), permit2, address(harness), recipient, permit, signature);
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenTransferReturnsFalse() external {
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            abi.encode(false)
        );

        vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
        harness.permitTransferAssetFrom(token.ERC20(amount), permit2, address(harness), recipient, permit, signature);
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        vm.expectRevert("Address: call to non-contract");
        harness.permitTransferAssetFrom(nonContractAddress.ERC20(amount), permit2, address(harness), recipient, permit, signature);
    }

    function test_shouldCallPermitTransferFrom_whenERC20_whenSourceIsNotThis() external {
        vm.expectCall(
            permit2,
            abi.encodeWithSelector(
                IPermit2Like.permitTransferFrom.selector,
                permit, IPermit2Like.SignatureTransferDetails(recipient, amount), source, signature
            )
        );
        harness.permitTransferAssetFrom(token.ERC20(amount), permit2, source, recipient, permit, signature);
    }

    function test_shouldFail_whenERC20_whenSourceIsNotThis_whenTransferReverts() external {
        vm.mockCallRevert(
            permit2,
            abi.encodeWithSelector(IPermit2Like.permitTransferFrom.selector),
            abi.encode("revert data")
        );

        vm.expectRevert("revert data");
        harness.permitTransferAssetFrom(token.ERC20(amount), permit2, source, recipient, permit, signature);
    }

    // ERC721

    function test_shouldFail_forUnsupportedCategory() external {
        Asset memory asset = Asset(Category.ERC20, token, id, amount);

        asset.category = Category.ERC721;
        vm.expectRevert("MultiToken: Unsupported category");
        harness.transferAssetFrom(asset, permit2, source, recipient);

        asset.category = Category.ERC1155;
        vm.expectRevert("MultiToken: Unsupported category");
        harness.transferAssetFrom(asset, permit2, source, recipient);

        asset.category = Category.CryptoKitties;
        vm.expectRevert("MultiToken: Unsupported category");
        harness.transferAssetFrom(asset, permit2, source, recipient);
    }

}


/*----------------------------------------------------------*|
|*  # GET TRANSFER AMOUNT                                   *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_GetTransferAmount_Test is Permit2MultiTokenTest {

    // ERC20

    function test_shouldReturnAssetAmount_whenERC20_whenNonZeroAmount() external {
        uint256 _amount = Permit2MultiToken.ERC20(token, amount).getTransferAmount();

        assertEq(_amount, amount);
    }

    function test_shouldReturnAssetAmount_whenERC20_whenZeroAmount() external {
        uint256 _amount = Permit2MultiToken.ERC20(token, 0).getTransferAmount();

        assertEq(_amount, 0);
    }

    // ERC721

    function test_shouldReturnOne_whenERC721() external {
        uint256 _amount = Permit2MultiToken.ERC721(token, id).getTransferAmount();

        assertEq(_amount, 1);
    }

    // ERC1155

    function test_shouldReturnAssetAmount_whenERC1155_whenNonZeroAmount() external {
        uint256 _amount = Permit2MultiToken.ERC1155(token, id, amount).getTransferAmount();

        assertEq(_amount, amount);
    }

    function test_shouldReturnOne_whenERC1155_whenZeroAmount() external {
        uint256 _amount = Permit2MultiToken.ERC1155(token, id, 0).getTransferAmount();

        assertEq(_amount, 1);
    }

    // CryptoKitties

    function test_shouldReturnOne_whenCryptoKitties() external {
        uint256 _amount = Permit2MultiToken.CryptoKitties(token, id).getTransferAmount();

        assertEq(_amount, 1);
    }

}


/*----------------------------------------------------------*|
|*  # BALANCE OF                                            *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_BalanceOf_Test is Permit2MultiTokenTest {

    function test_shouldReturnBalance_whenERC20() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC20.balanceOf.selector),
            abi.encode(amount)
        );

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC20.balanceOf.selector, source)
        );
        uint256 balance = Permit2MultiToken.ERC20(token, 10e18).balanceOf(source);

        assertEq(balance, amount);
    }

    function test_shouldReturnOne_whenERC721Owner() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC721.ownerOf.selector),
            abi.encode(source)
        );

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC721.ownerOf.selector, id)
        );
        uint256 balance = Permit2MultiToken.ERC721(token, id).balanceOf(source);

        assertEq(balance, 1);
    }

    function test_shouldReturnZero_whenNotERC721Owner() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC721.ownerOf.selector),
            abi.encode(address(0xffff))
        );

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC721.ownerOf.selector, id)
        );
        uint256 balance = Permit2MultiToken.ERC721(token, id).balanceOf(source);

        assertEq(balance, 0);
    }

    function test_shouldReturnBalance_whenERC1155() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC1155.balanceOf.selector),
            abi.encode(amount)
        );

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC1155.balanceOf.selector, source, id)
        );
        uint256 balance = Permit2MultiToken.ERC1155(token, id, 10e18).balanceOf(source);

        assertEq(balance, amount);
    }

    function test_shouldReturnOne_whenCryptoKittiesOwner() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(ICryptoKitties.ownerOf.selector),
            abi.encode(source)
        );

        vm.expectCall(
            token,
            abi.encodeWithSelector(ICryptoKitties.ownerOf.selector, id)
        );
        uint256 balance = Permit2MultiToken.CryptoKitties(token, id).balanceOf(source);

        assertEq(balance, 1);
    }

    function test_shouldReturnZero_whenNotCryptoKittiesOwner() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(ICryptoKitties.ownerOf.selector),
            abi.encode(address(0xffff))
        );

        vm.expectCall(
            token,
            abi.encodeWithSelector(ICryptoKitties.ownerOf.selector, id)
        );
        uint256 balance = Permit2MultiToken.CryptoKitties(token, id).balanceOf(source);

        assertEq(balance, 0);
    }

}


/*----------------------------------------------------------*|
|*  # IS VALID WITH REGISTRY                                *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_IsValidWithRegistry_Test is Permit2MultiTokenTest {

    function test_shouldReturnTrue_whenCategoryAndFormatCheckReturnTrue() external {
        // category check return false
        _mockRegistryCategory(0);
        asset = Permit2MultiToken.ERC721(token, id);
        assertFalse(asset.isValid(registry));

        // format check return false
        _mockRegistryCategory(1);
        asset = Permit2MultiToken.ERC721(token, id);
        asset.amount = 1;
        assertFalse(asset.isValid(registry));

        // both category and format check return true
        _mockRegistryCategory(1);
        asset = Permit2MultiToken.ERC721(token, id);
        assertTrue(asset.isValid(registry));
    }

}


/*----------------------------------------------------------*|
|*  # IS VALID WITHOUT REGISTRY                             *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_IsValidWithoutRegistry_Test is Permit2MultiTokenTest {

    function test_shouldReturnTrue_whenCategoryViaERC165AndFormatCheckReturnTrue() external {
        // category check return false
        _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, false);
        asset = Permit2MultiToken.ERC721(token, id);
        assertFalse(asset.isValid());

        // format check return false
        _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, true);
        asset = Permit2MultiToken.ERC721(token, id);
        asset.amount = 1;
        assertFalse(asset.isValid());

        // both category and format check return true
        _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, true);
        asset = Permit2MultiToken.ERC721(token, id);
        assertTrue(asset.isValid());
    }

}


/*----------------------------------------------------------*|
|*  # CHECK CATEGORY                                        *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_CheckCategory_Test is Permit2MultiTokenTest {

    function testFuzz_shouldReturnTrue_whenCategoryRegistered(uint8 _category) external {
        _category = _category % 4;
        _mockRegistryCategory(_category);
        asset = Asset(Category(_category), token, id, amount);

        assertTrue(asset._checkCategory(registry));
    }

    function testFuzz_shouldReturnFalse_whenDifferentCategoryRegistered(uint8 _category) external {
        _category = _category % 4;
        _mockRegistryCategory(_category + 1);
        asset = Asset(Category(_category), token, id, amount);

        assertFalse(asset._checkCategory(registry));
    }

    function testFuzz_shouldReturnTrue_whenCategoryNotRegistered_whenCheckViaERC165ReturnsTrue(
        uint8 _category,
        bool supportsERC165,
        bool supportsERC20,
        bool supportsERC721,
        bool supportsERC1155,
        bool supportsCryptoKitties
    ) external {
        _mockRegistryCategory(type(uint8).max);
        asset = Asset(Category(_category % 4), token, id, amount);

        if (supportsERC165) {
            _mockERC165Support(token, Permit2MultiToken.ERC20_INTERFACE_ID, supportsERC20);
            _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, supportsERC721);
            _mockERC165Support(token, Permit2MultiToken.ERC1155_INTERFACE_ID, supportsERC1155);
            _mockERC165Support(token, Permit2MultiToken.CRYPTO_KITTIES_INTERFACE_ID, supportsCryptoKitties);
        }

        assertEq(
            asset._checkCategory(registry),
            asset._checkCategoryViaERC165()
        );
    }

}


/*----------------------------------------------------------*|
|*  # CHECK CATEGORY VIA ERC165                             *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_CheckCategoryViaERC165_Test is Permit2MultiTokenTest {

    function test_shouldReturnFalse_whenZeroAddress() external {
        assertFalse(Permit2MultiToken.ERC20(address(0), amount).isValid());
        assertFalse(Permit2MultiToken.ERC721(address(0), id).isValid());
        assertFalse(Permit2MultiToken.ERC1155(address(0), id, amount).isValid());
        assertFalse(Permit2MultiToken.CryptoKitties(address(0), id).isValid());
    }

    function test_shouldReturnFalse_whenERC20_whenERC165SupportsERC721() external {
        _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, true);
        asset = Permit2MultiToken.ERC20(token, amount);

        assertFalse(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnFalse_whenERC20_whenERC165SupportsERC1155() external {
        _mockERC165Support(token, Permit2MultiToken.ERC1155_INTERFACE_ID, true);
        asset = Permit2MultiToken.ERC20(token, amount);

        assertFalse(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnFalse_whenERC20_whenERC165SupportsCryptoKitties() external {
        _mockERC165Support(token, Permit2MultiToken.CRYPTO_KITTIES_INTERFACE_ID, true);
        asset = Permit2MultiToken.ERC20(token, amount);

        assertFalse(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC20_whenERC165SupportsERC20() external {
        _mockERC165Support(token, Permit2MultiToken.ERC20_INTERFACE_ID, true);
        asset = Permit2MultiToken.ERC20(token, amount);

        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC20_whenERC165NotSupportsERC20_whenERC165NotSupportsERC721_whenERC165NotSupportsERC1155_whenERC165NotSupportsCryptoKitties() external {
        _mockERC165Support(token, Permit2MultiToken.ERC20_INTERFACE_ID, false);
        _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, false);
        _mockERC165Support(token, Permit2MultiToken.ERC1155_INTERFACE_ID, false);
        _mockERC165Support(token, Permit2MultiToken.CRYPTO_KITTIES_INTERFACE_ID, false);
        asset = Permit2MultiToken.ERC20(token, amount);

        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC721_whenERC165SupportsERC721Interface() external {
        asset = Permit2MultiToken.ERC721(token, id);

        _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, false);
        assertFalse(asset._checkCategoryViaERC165());

        _mockERC165Support(token, Permit2MultiToken.ERC721_INTERFACE_ID, true);
        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC1155_whenERC165SupportsERC1155Interface() external {
        asset = Permit2MultiToken.ERC1155(token, id, amount);

        _mockERC165Support(token, Permit2MultiToken.ERC1155_INTERFACE_ID, false);
        assertFalse(asset._checkCategoryViaERC165());

        _mockERC165Support(token, Permit2MultiToken.ERC1155_INTERFACE_ID, true);
        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenCryptoKitties_whenERC165SupportsCryptoKittiesInterface() external {
        asset = Permit2MultiToken.CryptoKitties(token, id);

        _mockERC165Support(token, Permit2MultiToken.CRYPTO_KITTIES_INTERFACE_ID, false);
        assertFalse(asset._checkCategoryViaERC165());

        _mockERC165Support(token, Permit2MultiToken.CRYPTO_KITTIES_INTERFACE_ID, true);
        assertTrue(asset._checkCategoryViaERC165());
    }

}


/*----------------------------------------------------------*|
|*  # CHECK FORMAT                                          *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_CheckFormat_Test is Permit2MultiTokenTest {

    function testFuzz_shouldReturnFalse_whenERC20WithNonZeroId(uint256 _id, uint256 _amount) external {
        vm.assume(_id > 0);

        asset = Permit2MultiToken.ERC20(token, _amount);
        asset.id = _id;

        assertFalse(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenERC20WithZeroId(uint256 _amount) external {
        asset = Permit2MultiToken.ERC20(token, _amount);

        assertTrue(asset._checkFormat());
    }

    function testFuzz_shouldReturnFalse_whenERC721WithNonZeroAmount(uint256 _id, uint256 _amount) external {
        vm.assume(_amount > 0);

        asset = Permit2MultiToken.ERC721(token, _id);
        asset.amount = _amount;

        assertFalse(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenERC721WithZeroAmount(uint256 _id) external {
        asset = Permit2MultiToken.ERC721(token, _id);

        assertTrue(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenERC1155(uint256 _id, uint256 _amount) external {
        asset = Permit2MultiToken.ERC1155(token, _id, _amount);

        assertTrue(asset._checkFormat());
    }

    function testFuzz_shouldReturnFalse_whenCryptoKittiesWithNonZeroAmount(uint256 _id, uint256 _amount) external {
        vm.assume(_amount > 0);

        asset = Permit2MultiToken.CryptoKitties(token, _id);
        asset.amount = _amount;

        assertFalse(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenCryptoKittiesWithZeroAmount(uint256 _id) external {
        asset = Permit2MultiToken.CryptoKitties(token, _id);

        assertTrue(asset._checkFormat());
    }

}


/*----------------------------------------------------------*|
|*  # IS SAME AS                                            *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_IsSameAs_Test is Permit2MultiTokenTest {

    function test_shouldFail_whenDifferentCategory() external {
        bool isSame = Permit2MultiToken.isSameAs(
            Asset(Category.ERC721, address(0xa66e7), 3312, 98e18),
            Asset(Category.ERC1155, address(0xa66e7), 3312, 98e18)
        );

        assertEq(isSame, false);
    }

    function test_shouldFail_whenDifferentAddress() external {
        bool isSame = Permit2MultiToken.isSameAs(
            Asset(Category.ERC721, address(0xa66e701), 3312, 98e18),
            Asset(Category.ERC721, address(0xa66e702), 3312, 98e18)
        );

        assertEq(isSame, false);
    }

    function test_shouldFail_whenDifferentId() external {
        bool isSame = Permit2MultiToken.isSameAs(
            Asset(Category.ERC721, address(0xa66e7), 1111, 98e18),
            Asset(Category.ERC721, address(0xa66e7), 2222, 98e18)
        );

        assertEq(isSame, false);
    }

    function test_shouldPass_whenDifferentAmount() external {
        bool isSame = Permit2MultiToken.isSameAs(
            Asset(Category.ERC721, address(0xa66e7), 3312, 1000e18),
            Asset(Category.ERC721, address(0xa66e7), 3312, 2000e18)
        );

        assertEq(isSame, true);
    }

}
