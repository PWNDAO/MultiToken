// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Test } from "forge-std/Test.sol";

import { IERC20 } from "openzeppelin/interfaces/IERC20.sol";
import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC1155 } from "openzeppelin/interfaces/IERC1155.sol";
import { IERC20Permit } from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";

import { MultiToken, ICryptoKitties, IMultiTokenCategoryRegistry } from "multitoken/MultiToken.sol";

import { MultiTokenHarness } from "test/harness/MultiTokenHarness.sol";

using MultiToken for address;

abstract contract MultiTokenTest is Test {

    address token = address(0xa66e7);
    address source = address(0xa11ce);
    address recipient = address(0xb0b);
    uint256 id = 373733;
    uint256 amount = 101e18;

    MultiToken.Asset asset;
    IMultiTokenCategoryRegistry registry = IMultiTokenCategoryRegistry(makeAddr("registry"));
    MultiTokenHarness harness = new MultiTokenHarness();

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

contract MultiToken_FactoryFunctions_Test is MultiTokenTest {

    function testFuzz_shouldReturnERC20(address assetAddress, uint256 _amount) external {
        MultiToken.Asset memory asset = MultiToken.ERC20(assetAddress, _amount);

        assertTrue(asset.category == MultiToken.Category.ERC20);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, 0);
        assertEq(asset.amount, _amount);
    }

    function test_shouldReturnERC721(address assetAddress, uint256 _id) external {
        MultiToken.Asset memory asset = MultiToken.ERC721(assetAddress, _id);

        assertTrue(asset.category == MultiToken.Category.ERC721);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, 0);
    }

    function test_shouldReturnERC1155_withZeroAmount(address assetAddress, uint256 _id) external {
        MultiToken.Asset memory asset = MultiToken.ERC1155(assetAddress, _id);

        assertTrue(asset.category == MultiToken.Category.ERC1155);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, 0);
    }

    function test_shouldReturnERC1155(address assetAddress, uint256 _id, uint256 _amount) external {
        MultiToken.Asset memory asset = MultiToken.ERC1155(assetAddress, _id, _amount);

        assertTrue(asset.category == MultiToken.Category.ERC1155);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, _amount);
    }

    function test_shouldReturnCryptoKitties(address assetAddress, uint256 _id) external {
        MultiToken.Asset memory asset = MultiToken.CryptoKitties(assetAddress, _id);

        assertTrue(asset.category == MultiToken.Category.CryptoKitties);
        assertEq(asset.assetAddress, assetAddress);
        assertEq(asset.id, _id);
        assertEq(asset.amount, 0);
    }

}


/*----------------------------------------------------------*|
|*  # TRANSFER ASSET FROM                                   *|
|*----------------------------------------------------------*/

contract MultiToken_TransferAssetFrom_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

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
    }


    // ERC20

    function test_shouldCallTransfer_whenERC20_whenSourceIsThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );
        MultiToken.ERC20(token, amount).transferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenTransferReturnsFalse() external {
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            abi.encode(false)
        );

        vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
        harness.transferAssetFrom(token.ERC20(amount), address(harness), recipient);
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        vm.expectRevert("Address: call to non-contract");
        harness.transferAssetFrom(nonContractAddress.ERC20(amount), address(harness), recipient);
    }

    function test_shouldCallTransferFrom_whenERC20_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
        );
        MultiToken.ERC20(token, amount).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    function test_shouldFail_whenERC20_whenSourceIsNotThis_whenTransferReturnsFalse() external {
        vm.clearMockedCalls();
        vm.mockCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount),
            abi.encode(false)
        );

        vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
        harness.transferAssetFrom(token.ERC20(amount), source, recipient);
    }

    function test_shouldFail_whenERC20_whenSourceIsNotThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        vm.expectRevert("Address: call to non-contract");
        harness.transferAssetFrom(nonContractAddress.ERC20(amount), source, recipient);
    }

    // ERC721

    function test_shouldCallTransferFrom_whenERC721() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
        MultiToken.ERC721(token, id).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // ERC1155

    function test_shouldCallSafeTransferFrom_whenERC1155() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
        );
        MultiToken.ERC1155(token, id, amount).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    function test_shouldSetAmountToOne_whenERC1155WithZeroAmount() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
        );
        MultiToken.ERC1155(token, id, 0).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // CryptoKitties

    function test_shouldCallTransferFrom_whenCryptoKitties_whenSourceIsThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, id)
        );
        MultiToken.CryptoKitties(token, id).transferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldCallTransferFrom_whenCryptoKitties_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
        MultiToken.CryptoKitties(token, id).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

}


/*----------------------------------------------------------*|
|*  # SAFE TRANSFER ASSET FROM                              *|
|*----------------------------------------------------------*/

contract MultiToken_SafeTransferAssetFrom_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

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
    }


    // ERC20

    function test_shouldCallTransfer_whenERC20_whenSourceIsThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );
        MultiToken.ERC20(token, amount).safeTransferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenTransferReturnsFalse() external {
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            abi.encode(false)
        );

        vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
        harness.safeTransferAssetFrom(token.ERC20(amount), address(harness), recipient);
    }

    function test_shouldFail_whenERC20_whenSourceIsThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        vm.expectRevert("Address: call to non-contract");
        harness.safeTransferAssetFrom(nonContractAddress.ERC20(amount), address(harness), recipient);
    }

    function test_shouldCallTransferFrom_whenERC20_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
        );
        MultiToken.ERC20(token, amount).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    function test_shouldFail_whenERC20_whenSourceIsNotThis_whenTransferReturnsFalse() external {
        vm.mockCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount),
            abi.encode(false)
        );

        vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
        harness.safeTransferAssetFrom(token.ERC20(amount), source, recipient);
    }

    function test_shouldFail_whenERC20_whenSourceIsNotThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        vm.expectRevert("Address: call to non-contract");
        harness.safeTransferAssetFrom(nonContractAddress.ERC20(amount), source, recipient);
    }

    // ERC721

    function test_shouldCallSafeTransferFrom_whenERC721() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", source, recipient, id, "")
        );
        MultiToken.ERC721(token, id).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // ERC1155

    function test_shouldCallSafeTransferFrom_whenERC1155() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
        );
        MultiToken.ERC1155(token, id, amount).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    function test_shouldSetAmountToOne_whenERC1155WithZeroAmount() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
        );
        MultiToken.ERC1155(token, id, 0).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // CryptoKitties

    function test_shouldCallTransferFrom_whenCryptoKitties_whenSourceIsThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, id)
        );
        MultiToken.CryptoKitties(token, id).safeTransferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldCallTransferFrom_whenCryptoKitties_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
        MultiToken.CryptoKitties(token, id).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

}


/*----------------------------------------------------------*|
|*  # GET TRANSFER AMOUNT                                   *|
|*----------------------------------------------------------*/

contract MultiToken_GetTransferAmount_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    // ERC20

    function test_shouldReturnAssetAmount_whenERC20_whenNonZeroAmount() external {
        uint256 _amount = MultiToken.ERC20(token, amount).getTransferAmount();

        assertEq(_amount, amount);
    }

    function test_shouldReturnAssetAmount_whenERC20_whenZeroAmount() external {
        uint256 _amount = MultiToken.ERC20(token, 0).getTransferAmount();

        assertEq(_amount, 0);
    }

    // ERC721

    function test_shouldReturnOne_whenERC721() external {
        uint256 _amount = MultiToken.ERC721(token, id).getTransferAmount();

        assertEq(_amount, 1);
    }

    // ERC1155

    function test_shouldReturnAssetAmount_whenERC1155_whenNonZeroAmount() external {
        uint256 _amount = MultiToken.ERC1155(token, id, amount).getTransferAmount();

        assertEq(_amount, amount);
    }

    function test_shouldReturnOne_whenERC1155_whenZeroAmount() external {
        uint256 _amount = MultiToken.ERC1155(token, id, 0).getTransferAmount();

        assertEq(_amount, 1);
    }

    // CryptoKitties

    function test_shouldReturnOne_whenCryptoKitties() external {
        uint256 _amount = MultiToken.CryptoKitties(token, id).getTransferAmount();

        assertEq(_amount, 1);
    }

}

/*----------------------------------------------------------*|
|*  # TRANSFER ASSET FROM CALLDATA                          *|
|*----------------------------------------------------------*/

contract MultiToken_TransferAssetFromCalldata_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function test_shouldReturnTransferCalldata_whenERC20_whenFromSender() external {
        bytes memory _calldata = MultiToken.ERC20(token, amount).transferAssetFromCalldata({
            source: address(this),
            dest: recipient,
            fromSender: true
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );
    }

    function test_shouldReturnTransferFromCalldata_whenERC20_whenNotFromSender() external {
        bytes memory _calldata = MultiToken.ERC20(token, amount).transferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
        );
    }

    function test_shouldReturnTransferFromCalldata_whenERC721() external {
        bytes memory _calldata = MultiToken.ERC721(token, id).transferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
    }

    function test_shouldReturnSafeTransferFromCalldata_whenERC1155() external {
        bytes memory _calldata = MultiToken.ERC1155(token, id, amount).transferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
        );
    }

    function test_shouldReturnAmountToOne_whenERC1155WithZeroAmount() external {
        bytes memory _calldata = MultiToken.ERC1155(token, id, 0).transferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
        );
    }

    function test_shouldReturnTransferFromCalldata_whenCryptoKitties_whenFromSender() external {
        bytes memory _calldata = MultiToken.CryptoKitties(token, id).transferAssetFromCalldata({
            source: address(this),
            dest: recipient,
            fromSender: true
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, id)
        );
    }

    function test_shouldReturnTransferFromCalldata_whenCryptoKitties_whenNotFromSender() external {
        bytes memory _calldata = MultiToken.CryptoKitties(token, id).transferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
    }

}


/*----------------------------------------------------------*|
|*  # SAFE TRANSFER ASSET FROM CALLDATA                     *|
|*----------------------------------------------------------*/

contract MultiToken_SafeTransferAssetFromCalldata_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function test_shouldReturnTransferCalldata_whenERC20_whenFromSender() external {
        bytes memory _calldata = MultiToken.ERC20(token, amount).safeTransferAssetFromCalldata({
            source: address(this),
            dest: recipient,
            fromSender: true
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );
    }

    function test_shouldReturnTransferFromCalldata_whenERC20_whenNotFromSender() external {
        bytes memory _calldata = MultiToken.ERC20(token, amount).safeTransferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
        );
    }

    function test_shouldReturnSafeTransferFromCalldata_whenERC721() external {
        bytes memory _calldata = MultiToken.ERC721(token, id).safeTransferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", source, recipient, id, "")
        );
    }

    function test_shouldReturnSafeTransferFromCalldata_whenERC1155() external {
        bytes memory _calldata = MultiToken.ERC1155(token, id, amount).safeTransferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
        );
    }

    function test_shouldReturnAmountToOne_whenERC1155WithZeroAmount() external {
        bytes memory _calldata = MultiToken.ERC1155(token, id, 0).safeTransferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
        );
    }

    function test_shouldReturnTransferFromCalldata_whenCryptoKitties_whenFromSender() external {
        bytes memory _calldata = MultiToken.CryptoKitties(token, id).safeTransferAssetFromCalldata({
            source: address(this),
            dest: recipient,
            fromSender: true
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, id)
        );
    }

    function test_shouldReturnTransferFromCalldata_whenCryptoKitties_whenNotFromSender() external {
        bytes memory _calldata = MultiToken.CryptoKitties(token, id).safeTransferAssetFromCalldata({
            source: source,
            dest: recipient,
            fromSender: false
        });

        assertEq(
            _calldata,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
    }

}


/*----------------------------------------------------------*|
|*  # PERMIT                                                *|
|*----------------------------------------------------------*/

contract MultiToken_Permit_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    address owner = address(0xaaaa);
    address spender = address(0xbbbb);
    uint256 deadline = 312333232;


    function test_shouldFail_whenERC721() external {
        vm.expectRevert("MultiToken::Permit: Unsupported category");
        harness.permit(token.ERC721(787282), owner, spender, bytes("permit signature"));
    }

    function test_shouldFail_whenERC1155() external {
        vm.expectRevert("MultiToken::Permit: Unsupported category");
        harness.permit(token.ERC1155(787282), owner, spender, bytes("permit signature"));
    }

    function test_shouldFail_whenPermitWithWrongLength() external {
        vm.expectRevert("MultiToken::Permit: Invalid permit length");
        harness.permit(token.ERC20(1), owner, spender, bytes("permit signature with wrong length"));
    }

    function test_shouldPass_whenStandardSignature() external {
        bytes32 r = 0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd;
        bytes32 s = 0x1234567890123456789012345678901234567890123456789012345678901234;
        uint8 v = 0xff;
        bytes memory permit = abi.encodePacked(deadline, r, s, v);

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC20Permit.permit.selector, owner, spender, amount, deadline, v, r, s)
        );
        MultiToken.ERC20(token, amount).permit({
            owner: owner,
            spender: spender,
            permitData: permit
        });
    }

    function test_shouldPass_whenCompactSignatureWithYParityZero() external {
        // Values copied from https://eips.ethereum.org/EIPS/eip-2098#test-cases
        bytes32 r = 0x68a020a209d3d56c46f38cc50a33f704f4a9a10a59377f8dd762ac66910e9b90;
        bytes32 s = 0x7e865ad05c4035ab5792787d4a0297a43617ae897930a6fe4d822b8faea52064;
        uint8 v = 27;
        bytes32 vs = 0x7e865ad05c4035ab5792787d4a0297a43617ae897930a6fe4d822b8faea52064;
        bytes memory permit = abi.encodePacked(deadline, r, vs);

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC20Permit.permit.selector, owner, spender, amount, deadline, v, r, s)
        );
        MultiToken.ERC20(token, amount).permit({
            owner: owner,
            spender: spender,
            permitData: permit
        });
    }

    function test_shouldPass_whenCompactSignatureWithYParityOne() external {
        // Values copied from https://eips.ethereum.org/EIPS/eip-2098#test-cases
        bytes32 r = 0x9328da16089fcba9bececa81663203989f2df5fe1faa6291a45381c81bd17f76;
        bytes32 s = 0x139c6d6b623b42da56557e5e734a43dc83345ddfadec52cbe24d0cc64f550793;
        uint8 v = 28;
        bytes32 vs = 0x939c6d6b623b42da56557e5e734a43dc83345ddfadec52cbe24d0cc64f550793;
        bytes memory permit = abi.encodePacked(deadline, r, vs);

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC20Permit.permit.selector, owner, spender, amount, deadline, v, r, s)
        );
        MultiToken.ERC20(token, amount).permit({
            owner: owner,
            spender: spender,
            permitData: permit
        });
    }

}


/*----------------------------------------------------------*|
|*  # BALANCE OF                                            *|
|*----------------------------------------------------------*/

contract MultiToken_BalanceOf_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

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
        uint256 balance = MultiToken.ERC20(token, 10e18).balanceOf(source);

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
        uint256 balance = MultiToken.ERC721(token, id).balanceOf(source);

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
        uint256 balance = MultiToken.ERC721(token, id).balanceOf(source);

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
        uint256 balance = MultiToken.ERC1155(token, id, 10e18).balanceOf(source);

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
        uint256 balance = MultiToken.CryptoKitties(token, id).balanceOf(source);

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
        uint256 balance = MultiToken.CryptoKitties(token, id).balanceOf(source);

        assertEq(balance, 0);
    }

}


/*----------------------------------------------------------*|
|*  # APPROVE ASSET                                         *|
|*----------------------------------------------------------*/

contract MultiToken_ApproveAsset_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function test_shouldCallApprove_whenERC20() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC20.approve.selector),
            abi.encode(true)
        );
        vm.mockCall(
            token,
            abi.encodeWithSelector(IERC20.allowance.selector),
            abi.encode(0)
        );

        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC20.approve.selector, recipient, amount)
        );
        MultiToken.ERC20(token, amount).approveAsset(recipient);
    }

    function test_shouldCallApprove_whenERC721() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC721.approve.selector, recipient, id)
        );
        MultiToken.ERC721(token, id).approveAsset(recipient);
    }

    function test_shouldCallSetApprovalForAll_whenERC1155() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC1155.setApprovalForAll.selector, recipient, true)
        );
        MultiToken.ERC1155(token, id, amount).approveAsset(recipient);
    }

    function test_shouldCallApprove_whenCryptoKitties() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(ICryptoKitties.approve.selector, recipient, id)
        );
        MultiToken.CryptoKitties(token, id).approveAsset(recipient);
    }

}


/*----------------------------------------------------------*|
|*  # IS VALID WITH REGISTRY                                *|
|*----------------------------------------------------------*/

contract MultiToken_IsValidWithRegistry_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function test_shouldReturnTrue_whenCategoryAndFormatCheckReturnTrue() external {
        // category check return false
        _mockRegistryCategory(0);
        asset = MultiToken.ERC721(token, id);
        assertFalse(asset.isValid(registry));

        // format check return false
        _mockRegistryCategory(1);
        asset = MultiToken.ERC721(token, id);
        asset.amount = 1;
        assertFalse(asset.isValid(registry));

        // both category and format check return true
        _mockRegistryCategory(1);
        asset = MultiToken.ERC721(token, id);
        assertTrue(asset.isValid(registry));
    }

}


/*----------------------------------------------------------*|
|*  # IS VALID WITHOUT REGISTRY                             *|
|*----------------------------------------------------------*/

contract MultiToken_IsValidWithoutRegistry_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function test_shouldReturnTrue_whenCategoryViaERC165AndFormatCheckReturnTrue() external {
        // category check return false
        _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, false);
        asset = MultiToken.ERC721(token, id);
        assertFalse(asset.isValid());

        // format check return false
        _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, true);
        asset = MultiToken.ERC721(token, id);
        asset.amount = 1;
        assertFalse(asset.isValid());

        // both category and format check return true
        _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, true);
        asset = MultiToken.ERC721(token, id);
        assertTrue(asset.isValid());
    }

}


/*----------------------------------------------------------*|
|*  # CHECK CATEGORY                                        *|
|*----------------------------------------------------------*/

contract MultiToken_CheckCategory_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function testFuzz_shouldReturnTrue_whenCategoryRegistered(uint8 _category) external {
        _category = _category % 4;
        _mockRegistryCategory(_category);
        asset = MultiToken.Asset(MultiToken.Category(_category), token, id, amount);

        assertTrue(asset._checkCategory(registry));
    }

    function testFuzz_shouldReturnFalse_whenDifferentCategoryRegistered(uint8 _category) external {
        _category = _category % 4;
        _mockRegistryCategory(_category + 1);
        asset = MultiToken.Asset(MultiToken.Category(_category), token, id, amount);

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
        asset = MultiToken.Asset(MultiToken.Category(_category % 4), token, id, amount);

        if (supportsERC165) {
            _mockERC165Support(token, MultiToken.ERC20_INTERFACE_ID, supportsERC20);
            _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, supportsERC721);
            _mockERC165Support(token, MultiToken.ERC1155_INTERFACE_ID, supportsERC1155);
            _mockERC165Support(token, MultiToken.CRYPTO_KITTIES_INTERFACE_ID, supportsCryptoKitties);
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

contract MultiToken_CheckCategoryViaERC165_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function test_shouldReturnFalse_whenZeroAddress() external {
        assertFalse(MultiToken.ERC20(address(0), amount).isValid());
        assertFalse(MultiToken.ERC721(address(0), id).isValid());
        assertFalse(MultiToken.ERC1155(address(0), id, amount).isValid());
        assertFalse(MultiToken.CryptoKitties(address(0), id).isValid());
    }

    function test_shouldReturnFalse_whenERC20_whenERC165SupportsERC721() external {
        _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, true);
        asset = MultiToken.ERC20(token, amount);

        assertFalse(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnFalse_whenERC20_whenERC165SupportsERC1155() external {
        _mockERC165Support(token, MultiToken.ERC1155_INTERFACE_ID, true);
        asset = MultiToken.ERC20(token, amount);

        assertFalse(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnFalse_whenERC20_whenERC165SupportsCryptoKitties() external {
        _mockERC165Support(token, MultiToken.CRYPTO_KITTIES_INTERFACE_ID, true);
        asset = MultiToken.ERC20(token, amount);

        assertFalse(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC20_whenERC165SupportsERC20() external {
        _mockERC165Support(token, MultiToken.ERC20_INTERFACE_ID, true);
        asset = MultiToken.ERC20(token, amount);

        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC20_whenERC165NotSupportsERC20_whenERC165NotSupportsERC721_whenERC165NotSupportsERC1155_whenERC165NotSupportsCryptoKitties() external {
        _mockERC165Support(token, MultiToken.ERC20_INTERFACE_ID, false);
        _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, false);
        _mockERC165Support(token, MultiToken.ERC1155_INTERFACE_ID, false);
        _mockERC165Support(token, MultiToken.CRYPTO_KITTIES_INTERFACE_ID, false);
        asset = MultiToken.ERC20(token, amount);

        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC721_whenERC165SupportsERC721Interface() external {
        asset = MultiToken.ERC721(token, id);

        _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, false);
        assertFalse(asset._checkCategoryViaERC165());

        _mockERC165Support(token, MultiToken.ERC721_INTERFACE_ID, true);
        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenERC1155_whenERC165SupportsERC1155Interface() external {
        asset = MultiToken.ERC1155(token, id, amount);

        _mockERC165Support(token, MultiToken.ERC1155_INTERFACE_ID, false);
        assertFalse(asset._checkCategoryViaERC165());

        _mockERC165Support(token, MultiToken.ERC1155_INTERFACE_ID, true);
        assertTrue(asset._checkCategoryViaERC165());
    }

    function test_shouldReturnTrue_whenCryptoKitties_whenERC165SupportsCryptoKittiesInterface() external {
        asset = MultiToken.CryptoKitties(token, id);

        _mockERC165Support(token, MultiToken.CRYPTO_KITTIES_INTERFACE_ID, false);
        assertFalse(asset._checkCategoryViaERC165());

        _mockERC165Support(token, MultiToken.CRYPTO_KITTIES_INTERFACE_ID, true);
        assertTrue(asset._checkCategoryViaERC165());
    }

}


/*----------------------------------------------------------*|
|*  # CHECK FORMAT                                          *|
|*----------------------------------------------------------*/

contract MultiToken_CheckFormat_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function testFuzz_shouldReturnFalse_whenERC20WithNonZeroId(uint256 _id, uint256 _amount) external {
        vm.assume(_id > 0);

        asset = MultiToken.ERC20(token, _amount);
        asset.id = _id;

        assertFalse(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenERC20WithZeroId(uint256 _amount) external {
        asset = MultiToken.ERC20(token, _amount);

        assertTrue(asset._checkFormat());
    }

    function testFuzz_shouldReturnFalse_whenERC721WithNonZeroAmount(uint256 _id, uint256 _amount) external {
        vm.assume(_amount > 0);

        asset = MultiToken.ERC721(token, _id);
        asset.amount = _amount;

        assertFalse(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenERC721WithZeroAmount(uint256 _id) external {
        asset = MultiToken.ERC721(token, _id);

        assertTrue(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenERC1155(uint256 _id, uint256 _amount) external {
        asset = MultiToken.ERC1155(token, _id, _amount);

        assertTrue(asset._checkFormat());
    }

    function testFuzz_shouldReturnFalse_whenCryptoKittiesWithNonZeroAmount(uint256 _id, uint256 _amount) external {
        vm.assume(_amount > 0);

        asset = MultiToken.CryptoKitties(token, _id);
        asset.amount = _amount;

        assertFalse(asset._checkFormat());
    }

    function testFuzz_shouldReturnTrue_whenCryptoKittiesWithZeroAmount(uint256 _id) external {
        asset = MultiToken.CryptoKitties(token, _id);

        assertTrue(asset._checkFormat());
    }

}


/*----------------------------------------------------------*|
|*  # IS SAME AS                                            *|
|*----------------------------------------------------------*/

contract MultiToken_IsSameAs_Test is MultiTokenTest {

    function test_shouldFail_whenDifferentCategory() external {
        bool isSame = MultiToken.isSameAs(
            MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 3312, 98e18),
            MultiToken.Asset(MultiToken.Category.ERC1155, address(0xa66e7), 3312, 98e18)
        );

        assertEq(isSame, false);
    }

    function test_shouldFail_whenDifferentAddress() external {
        bool isSame = MultiToken.isSameAs(
            MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e701), 3312, 98e18),
            MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e702), 3312, 98e18)
        );

        assertEq(isSame, false);
    }

    function test_shouldFail_whenDifferentId() external {
        bool isSame = MultiToken.isSameAs(
            MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 1111, 98e18),
            MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 2222, 98e18)
        );

        assertEq(isSame, false);
    }

    function test_shouldPass_whenDifferentAmount() external {
        bool isSame = MultiToken.isSameAs(
            MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 3312, 1000e18),
            MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 3312, 2000e18)
        );

        assertEq(isSame, true);
    }

}
