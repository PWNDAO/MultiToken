// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "@openzeppelin/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/interfaces/IERC20.sol";
import "@openzeppelin/interfaces/IERC721.sol";
import "@openzeppelin/interfaces/IERC1155.sol";

import "@MT/interfaces/ICryptoKitties.sol";
import "@MT/MultiToken.sol";


abstract contract MultiTokenTest is Test {

    address token = address(0xa66e7);
    address source = address(0xa11ce);
    address recipient = address(0xb0b);
    uint256 id = 373733;
    uint256 amount = 101e18;

    constructor() {
        vm.etch(token, bytes("0x01"));
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
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).transferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    // vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
    function testFail_shouldFail_whenERC20_whenSourceIsThis_whenTransferReturnsFalse() external {
        vm.clearMockedCalls();
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            abi.encode(false)
        );

        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).transferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    // vm.expectRevert("Address: call to non-contract");
    function testFail_shouldFail_whenERC20_whenSourceIsThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        MultiToken.Asset(MultiToken.Category.ERC20, nonContractAddress, 0, amount).transferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldCallTransferFrom_whenERC20_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
        );
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
    function testFail_shouldFail_whenERC20_whenSourceIsNotThis_whenTransferReturnsFalse() external {
        vm.clearMockedCalls();
        vm.mockCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount),
            abi.encode(false)
        );

        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // vm.expectRevert("Address: call to non-contract");
    function testFail_shouldFail_whenERC20_whenSourceIsNotThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        MultiToken.Asset(MultiToken.Category.ERC20, nonContractAddress, 0, amount).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // ERC721

    function test_shouldCallTransferFrom_whenERC721() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
        MultiToken.Asset(MultiToken.Category.ERC721, token, id, 0).transferAssetFrom({
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
        MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).transferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    function test_shouldSetAmountToOne_whenERC1155WithZeroAmount() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
        );
        MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0).transferAssetFrom({
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
        MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).transferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldCallTransferFrom_whenCryptoKitties_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
        MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).transferAssetFrom({
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
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).safeTransferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    // vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
    function testFail_shouldFail_whenERC20_whenSourceIsThis_whenTransferReturnsFalse() external {
        vm.clearMockedCalls();
        vm.mockCall(
            token,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount),
            abi.encode(false)
        );

        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).safeTransferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    // vm.expectRevert("Address: call to non-contract");
    function testFail_shouldFail_whenERC20_whenSourceIsThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        MultiToken.Asset(MultiToken.Category.ERC20, nonContractAddress, 0, amount).safeTransferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldCallTransferFrom_whenERC20_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
        );
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // vm.expectRevert("SafeERC20: ERC20 operation did not succeed");
    function testFail_shouldFail_whenERC20_whenSourceIsNotThis_whenTransferReturnsFalse() external {
        vm.clearMockedCalls();
        vm.mockCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount),
            abi.encode(false)
        );

        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // vm.expectRevert("Address: call to non-contract");
    function testFail_shouldFail_whenERC20_whenSourceIsNotThis_whenCallToNonContractAddress() external {
        address nonContractAddress = address(0xff22ff33);

        MultiToken.Asset(MultiToken.Category.ERC20, nonContractAddress, 0, amount).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    // ERC721

    function test_shouldCallSafeTransferFrom_whenERC721() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", source, recipient, id, "")
        );
        MultiToken.Asset(MultiToken.Category.ERC721, token, id, 0).safeTransferAssetFrom({
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
        MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).safeTransferAssetFrom({
            source: source,
            dest: recipient
        });
    }

    function test_shouldSetAmountToOne_whenERC1155WithZeroAmount() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
        );
        MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0).safeTransferAssetFrom({
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
        MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).safeTransferAssetFrom({
            source: address(this),
            dest: recipient
        });
    }

    function test_shouldCallTransferFrom_whenCryptoKitties_whenSourceIsNotThis() external {
        vm.expectCall(
            token,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
        );
        MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).safeTransferAssetFrom({
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
        uint256 _amount = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).getTransferAmount();

        assertEq(_amount, amount);
    }

    function test_shouldReturnAssetAmount_whenERC20_whenZeroAmount() external {
        uint256 _amount = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, 0).getTransferAmount();

        assertEq(_amount, 0);
    }

    // ERC721

    function test_shouldReturnOne_whenERC721() external {
        uint256 _amount = MultiToken.Asset(MultiToken.Category.ERC721, token, id, 0).getTransferAmount();

        assertEq(_amount, 1);
    }

    // ERC1155

    function test_shouldReturnAssetAmount_whenERC1155_whenNonZeroAmount() external {
        uint256 _amount = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).getTransferAmount();

        assertEq(_amount, amount);
    }

    function test_shouldReturnOne_whenERC1155_whenZeroAmount() external {
        uint256 _amount = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0).getTransferAmount();

        assertEq(_amount, 1);
    }

    // CryptoKitties

    function test_shouldReturnOne_whenCryptoKitties() external {
        uint256 _amount = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).getTransferAmount();

        assertEq(_amount, 1);
    }

}

/*----------------------------------------------------------*|
|*  # TRANSFER ASSET FROM CALLDATA                          *|
|*----------------------------------------------------------*/

contract MultiToken_TransferAssetFromCalldata_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function test_shouldReturnTransferCalldata_whenERC20_whenFromSender() external {
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).transferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).transferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC721, token, id, 0).transferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).transferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0).transferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).transferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).transferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).safeTransferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).safeTransferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC721, token, id, 0).safeTransferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).safeTransferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0).safeTransferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).safeTransferAssetFromCalldata({
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
        bytes memory _calldata = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).safeTransferAssetFromCalldata({
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
        MultiToken.Asset(MultiToken.Category.ERC721, token, 787282, 1).permit({
            owner: owner,
            spender: spender,
            permitData: bytes("permit signature")
        });
    }

    function test_shouldFail_whenERC1155() external {
        vm.expectRevert("MultiToken::Permit: Unsupported category");
        MultiToken.Asset(MultiToken.Category.ERC1155, token, 787282, 1).permit({
            owner: owner,
            spender: spender,
            permitData: bytes("permit signature")
        });
    }

    function test_shouldFail_whenPermitWithWrongLength() external {
        vm.expectRevert("MultiToken::Permit: Invalid permit length");
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, 1).permit({
            owner: owner,
            spender: spender,
            permitData: bytes("permit signature with wrong length")
        });
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
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).permit({
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
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).permit({
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
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).permit({
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
        uint256 balance = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, 10e18).balanceOf(source);

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
        uint256 balance = MultiToken.Asset(MultiToken.Category.ERC721, token, id, 1).balanceOf(source);

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
        uint256 balance = MultiToken.Asset(MultiToken.Category.ERC721, token, id, 1).balanceOf(source);

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
        uint256 balance = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 10e18).balanceOf(source);

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
        uint256 balance = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 1).balanceOf(source);

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
        uint256 balance = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 1).balanceOf(source);

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
        MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).approveAsset(recipient);
    }

    function test_shouldCallApprove_whenERC721() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC721.approve.selector, recipient, id)
        );
        MultiToken.Asset(MultiToken.Category.ERC721, token, id, 1).approveAsset(recipient);
    }

    function test_shouldCallSetApprovalForAll_whenERC1155() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(IERC1155.setApprovalForAll.selector, recipient, true)
        );
        MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).approveAsset(recipient);
    }

    function test_shouldCallApprove_whenCryptoKitties() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(ICryptoKitties.approve.selector, recipient, id)
        );
        MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 1).approveAsset(recipient);
    }

}


/*----------------------------------------------------------*|
|*  # IS VALID                                              *|
|*----------------------------------------------------------*/

contract MultiToken_IsValid_Test is MultiTokenTest {
    using MultiToken for MultiToken.Asset;

    function _mockERC165Token(address _token) private {
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
    }

    function _mockERC20Token(address _token) private {
        // No need to mock any call
    }

    function _mockERC721Token(address _token) private {
        _mockERC165Token(_token);

        vm.mockCall(
            _token,
            abi.encodeWithSignature("supportsInterface(bytes4)", MultiToken.ERC721_INTERFACE_ID),
            abi.encode(true)
        );
    }

    function _mockERC1155Token(address _token) private {
        _mockERC165Token(_token);

        vm.mockCall(
            _token,
            abi.encodeWithSignature("supportsInterface(bytes4)", MultiToken.ERC1155_INTERFACE_ID),
            abi.encode(true)
        );
    }

    function _mockCryptoKittiesToken(address _token) private {
        _mockERC165Token(_token);

        vm.mockCall(
            _token,
            abi.encodeWithSignature("supportsInterface(bytes4)", MultiToken.CRYPTO_KITTIES_INTERFACE_ID),
            abi.encode(true)
        );
    }


    // General

    function test_shouldFail_whenNoContractAddress() external {
        bool isValid = MultiToken.Asset(MultiToken.Category.ERC20, address(0), 0, amount).isValid();

        assertEq(isValid, false);
    }

    // ERC20

    function test_shouldFail_whenERC20WithNonZeroId() external {
        _mockERC20Token(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC20, token, id, amount).isValid();

        assertEq(isValid, false);
    }

    function test_shouldFail_whenERC20WithERC165_notSupportingIERC20() external {
        _mockERC20Token(token);

        _mockERC165Token(token);
        vm.mockCall(
            token,
            abi.encodeWithSignature("supportsInterface(bytes4)", MultiToken.ERC20_INTERFACE_ID),
            abi.encode(false)
        );

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).isValid();

        assertEq(isValid, false);
    }

    function test_shouldPass_whenERC20WithERC165_supportingIERC20() external {
        _mockERC20Token(token);

        _mockERC165Token(token);
        vm.mockCall(
            token,
            abi.encodeWithSignature("supportsInterface(bytes4)", MultiToken.ERC20_INTERFACE_ID),
            abi.encode(true)
        );

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).isValid();

        assertEq(isValid, true);
    }

    function test_shouldPass_whenValidERC20() external {
        _mockERC20Token(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount).isValid();

        assertEq(isValid, true);
    }

    function test_shouldPass_whenERC20WithZeroAmount() external {
        _mockERC20Token(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC20, token, 0, 0).isValid();

        assertEq(isValid, true);
    }

    // ERC721

    function test_shouldFail_whenERC721WithNonZeroAmount() external {
        _mockERC721Token(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC721, token, id, amount).isValid();

        assertEq(isValid, false);
    }

    function test_shouldFail_whenNotSupportingERC721Interface() external {
        // Not mocking ERC721 token

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC721, token, id, 0).isValid();

        assertEq(isValid, false);
    }

    function test_shouldPass_whenValidERC721() external {
        _mockERC721Token(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC721, token, id, 0).isValid();

        assertEq(isValid, true);
    }

    // ERC1155

    function test_shouldFail_whenNotSupportingERC1155Interface() external {
        // Not mocking ERC1155 token

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).isValid();

        assertEq(isValid, false);
    }

    function test_shouldPass_whenValidERC1155() external {
        _mockERC1155Token(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount).isValid();

        assertEq(isValid, true);
    }

    function test_shouldPass_whenERC1155WithZeroAmount() external {
        _mockERC1155Token(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0).isValid();

        assertEq(isValid, true);
    }

    // CryptoKitties

    function test_shouldFail_whenCryptoKittiesWithNonZeroAmount() external {
        _mockCryptoKittiesToken(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, amount).isValid();

        assertEq(isValid, false);
    }

    function test_shouldFail_whenNotSupportingCryptoKittiesInterface() external {
        // Not mocking CryptoKitties token

        bool isValid = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).isValid();

        assertEq(isValid, false);
    }

    function test_shouldPass_whenValidCryptoKitties() external {
        _mockCryptoKittiesToken(token);

        bool isValid = MultiToken.Asset(MultiToken.Category.CryptoKitties, token, id, 0).isValid();

        assertEq(isValid, true);
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
