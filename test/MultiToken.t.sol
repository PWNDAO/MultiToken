// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "../src/MultiToken.sol";


/*----------------------------------------------------------*|
|*  # TRANSFER ASSET FROM                                   *|
|*----------------------------------------------------------*/

contract MultiToken_TransferAssetFrom_Test is Test {

	address token = address(0xa66e7);
	address source = address(0xa11ce);
	address recipient = address(0xb0b);
	uint256 id = 373733;
	uint256 amount = 101e18;

	function setUp() external {
		vm.etch(address(token), bytes("0x01"));
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


	function test_shouldCallTransfer_whenERC20_whenSourceIsThis() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
		);
		MultiToken.transferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			address(this),
			recipient
		);
	}

	function test_shouldCallTransferFrom_whenERC20_whenSourceIsNotThis() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
		);
		MultiToken.transferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			source,
			recipient
		);
	}

	function test_shouldCallTransferFrom_whenERC721() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
		);
		MultiToken.transferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC721, token, id, 1),
			source,
			recipient
		);
	}

	function test_shouldCallSafeTransferFrom_whenERC1155() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
		);
		MultiToken.transferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount),
			source,
			recipient
		);
	}

	function test_shouldSetAmountToOne_whenERC1155WithZeroAmount() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
		);
		MultiToken.transferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0),
			source,
			recipient
		);
	}

}


/*----------------------------------------------------------*|
|*  # SAFE TRANSFER ASSET FROM                              *|
|*----------------------------------------------------------*/

contract MultiToken_SafeTransferAssetFrom_Test is Test {

	address token = address(0xa66e7);
	address source = address(0xa11ce);
	address recipient = address(0xb0b);
	uint256 id = 373733;
	uint256 amount = 101e18;

	function setUp() external {
		vm.etch(address(token), bytes("0x01"));
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


	function test_shouldCallTransfer_whenERC20_whenSourceIsThis() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
		);
		MultiToken.safeTransferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			address(this),
			recipient
		);
	}

	function test_shouldCallTransferFrom_whenERC20_whenSourceIsNotThis() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
		);
		MultiToken.safeTransferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			source,
			recipient
		);
	}

	function test_shouldCallSafeTransferFrom_whenERC721() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", source, recipient, id, "")
		);
		MultiToken.safeTransferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC721, token, id, 1),
			source,
			recipient
		);
	}

	function test_shouldCallSafeTransferFrom_whenERC1155() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
		);
		MultiToken.safeTransferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount),
			source,
			recipient
		);
	}

	function test_shouldSetAmountToOne_whenERC1155WithZeroAmount() external {
		vm.expectCall(
			token,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
		);
		MultiToken.safeTransferAssetFrom(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0),
			source,
			recipient
		);
	}

}


/*----------------------------------------------------------*|
|*  # TRANSFER ASSET FROM CALLDATA                          *|
|*----------------------------------------------------------*/

contract MultiToken_TransferAssetFromCalldata_Test is Test {

	address token = address(0xa66e7);
	address source = address(0xa11ce);
	address recipient = address(0xb0b);
	uint256 id = 373733;
	uint256 amount = 101e18;


	function test_shouldReturnTransferCalldata_whenERC20_whenFromSender() external {
		bytes memory _calldata = MultiToken.transferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			address(this),
			recipient,
			true
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
		);
	}

	function test_shouldReturnTransferFromCalldata_whenERC20_whenNotFromSender() external {
		bytes memory _calldata = MultiToken.transferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
		);
	}

	function test_shouldReturnTransferFromCalldata_whenERC721() external {
		bytes memory _calldata = MultiToken.transferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC721, token, id, 1),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, id)
		);
	}

	function test_shouldReturnSafeTransferFromCalldata_whenERC1155() external {
		bytes memory _calldata = MultiToken.transferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
		);
	}

	function test_shouldReturnAmountToOne_whenERC1155WithZeroAmount() external {
		bytes memory _calldata = MultiToken.transferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
		);
	}

}


/*----------------------------------------------------------*|
|*  # SAFE TRANSFER ASSET FROM CALLDATA                     *|
|*----------------------------------------------------------*/

contract MultiToken_SafeTransferAssetFromCalldata_Test is Test {

	address token = address(0xa66e7);
	address source = address(0xa11ce);
	address recipient = address(0xb0b);
	uint256 id = 373733;
	uint256 amount = 101e18;


	function test_shouldReturnTransferCalldata_whenERC20_whenFromSender() external {
		bytes memory _calldata = MultiToken.safeTransferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			address(this),
			recipient,
			true
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
		);
	}

	function test_shouldReturnTransferFromCalldata_whenERC20_whenNotFromSender() external {
		bytes memory _calldata = MultiToken.safeTransferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC20, token, 0, amount),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("transferFrom(address,address,uint256)", source, recipient, amount)
		);
	}

	function test_shouldReturnSafeTransferFromCalldata_whenERC721() external {
		bytes memory _calldata = MultiToken.safeTransferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC721, token, id, 1),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", source, recipient, id, "")
		);
	}

	function test_shouldReturnSafeTransferFromCalldata_whenERC1155() external {
		bytes memory _calldata = MultiToken.safeTransferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, amount),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, amount, "")
		);
	}

	function test_shouldReturnAmountToOne_whenERC1155WithZeroAmount() external {
		bytes memory _calldata = MultiToken.safeTransferAssetFromCalldata(
			MultiToken.Asset(MultiToken.Category.ERC1155, token, id, 0),
			source,
			recipient,
			false
		);

		assertEq(
			_calldata,
			abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", source, recipient, id, 1, "")
		);
	}

}


/*----------------------------------------------------------*|
|*  # PERMIT                                                *|
|*----------------------------------------------------------*/

contract MultiToken_Permit_Test is Test {

	function test_shouldFail_whenERC721() external {
		vm.expectRevert("MultiToken::Permit: Unsupported category");
		MultiToken.permit(
			MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 787282, 1),
			address(0xaaaa),
			address(0xbbbb),
			bytes("permit signature")
		);
	}

	function test_shouldFail_whenERC1155() external {
		vm.expectRevert("MultiToken::Permit: Unsupported category");
		MultiToken.permit(
			MultiToken.Asset(MultiToken.Category.ERC1155, address(0xa66e7), 787282, 1),
			address(0xaaaa),
			address(0xbbbb),
			bytes("permit signature")
		);
	}

	function test_shouldFail_whenPermitWithWrongLength() external {
		vm.expectRevert("MultiToken::Permit: Invalid permit length");
		MultiToken.permit(
			MultiToken.Asset(MultiToken.Category.ERC20, address(0xa66e7), 0, 1),
			address(0xaaaa),
			address(0xbbbb),
			bytes("permit signature with wrong length")
		);
	}

	function test_shouldPass_whenStandardSignature() external {
		address tokenAddr = address(0xa66e7);
		address owner = address(0xaaaa);
		address spender = address(0xbbbb);
		uint256 amount = 87673e18;
		uint256 deadline = 312333232;
		bytes32 r = 0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd;
		bytes32 s =0x1234567890123456789012345678901234567890123456789012345678901234;
		uint8 v = 0xff;
		bytes memory permit = abi.encodePacked(deadline, r, s, v);

		vm.etch(tokenAddr, bytes("0x01"));

		vm.expectCall(
			tokenAddr,
			abi.encodeWithSelector(IERC20Permit.permit.selector, owner, spender, amount, deadline, v, r, s)
		);
		MultiToken.permit(
			MultiToken.Asset(MultiToken.Category.ERC20, tokenAddr, 0, amount),
			owner,
			spender,
			permit
		);
	}

	function test_shouldPass_whenCompactSignatureWithYParityZero() external {
		address tokenAddr = address(0xa66e7);
		address owner = address(0xaaaa);
		address spender = address(0xbbbb);
		uint256 amount = 87673e18;
		uint256 deadline = 312333232;
		// Values copied from https://eips.ethereum.org/EIPS/eip-2098#test-cases
		bytes32 r = 0x68a020a209d3d56c46f38cc50a33f704f4a9a10a59377f8dd762ac66910e9b90;
		bytes32 s =0x7e865ad05c4035ab5792787d4a0297a43617ae897930a6fe4d822b8faea52064;
		uint8 v = 27;
		bytes32 vs = 0x7e865ad05c4035ab5792787d4a0297a43617ae897930a6fe4d822b8faea52064;
		bytes memory permit = abi.encodePacked(deadline, r, vs);

		vm.etch(tokenAddr, bytes("0x01"));

		vm.expectCall(
			tokenAddr,
			abi.encodeWithSelector(IERC20Permit.permit.selector, owner, spender, amount, deadline, v, r, s)
		);
		MultiToken.permit(
			MultiToken.Asset(MultiToken.Category.ERC20, tokenAddr, 0, amount),
			owner,
			spender,
			permit
		);
	}

	function test_shouldPass_whenCompactSignatureWithYParityOne() external {
		address tokenAddr = address(0xa66e7);
		address owner = address(0xaaaa);
		address spender = address(0xbbbb);
		uint256 amount = 87673e18;
		uint256 deadline = 312333232;
		// Values copied from https://eips.ethereum.org/EIPS/eip-2098#test-cases
		bytes32 r = 0x9328da16089fcba9bececa81663203989f2df5fe1faa6291a45381c81bd17f76;
		bytes32 s =0x139c6d6b623b42da56557e5e734a43dc83345ddfadec52cbe24d0cc64f550793;
		uint8 v = 28;
		bytes32 vs = 0x939c6d6b623b42da56557e5e734a43dc83345ddfadec52cbe24d0cc64f550793;
		bytes memory permit = abi.encodePacked(deadline, r, vs);

		vm.etch(tokenAddr, bytes("0x01"));

		vm.expectCall(
			tokenAddr,
			abi.encodeWithSelector(IERC20Permit.permit.selector, owner, spender, amount, deadline, v, r, s)
		);
		MultiToken.permit(
			MultiToken.Asset(MultiToken.Category.ERC20, tokenAddr, 0, amount),
			owner,
			spender,
			permit
		);
	}

}


/*----------------------------------------------------------*|
|*  # BALANCE OF                                            *|
|*----------------------------------------------------------*/

contract MultiToken_BalanceOf_Test is Test {

	function test_shouldReturnBalance_whenERC20() external {
		IERC20 token = IERC20(address(0xa66e7));
		address target = address(0xb0b);
		uint256 balanceMock = 101e18;

		vm.etch(address(token), bytes("0x01"));
		vm.mockCall(
			address(token),
			abi.encodeWithSelector(token.balanceOf.selector),
			abi.encode(balanceMock)
		);

		vm.expectCall(
			address(token),
			abi.encodeWithSelector(token.balanceOf.selector, target)
		);
		uint256 balance = MultiToken.balanceOf(
			MultiToken.Asset(MultiToken.Category.ERC20, address(token), 0, 10e18),
			target
		);
		assertEq(balance, balanceMock);
	}

	function test_shouldReturnOne_whenERC721Owner() external {
		IERC721 token = IERC721(address(0xa66e7));
		address target = address(0xb0b);
		uint256 id = 8765678;

		vm.etch(address(token), bytes("0x01"));
		vm.mockCall(
			address(token),
			abi.encodeWithSelector(token.ownerOf.selector),
			abi.encode(target)
		);

		vm.expectCall(
			address(token),
			abi.encodeWithSelector(token.ownerOf.selector, id)
		);
		uint256 balance = MultiToken.balanceOf(
			MultiToken.Asset(MultiToken.Category.ERC721, address(token), id, 1),
			target
		);
		assertEq(balance, 1);
	}

	function test_shouldReturnZero_whenNotERC721Owner() external {
		IERC721 token = IERC721(address(0xa66e7));
		address target = address(0xb0b);
		uint256 id = 8765678;

		vm.etch(address(token), bytes("0x01"));
		vm.mockCall(
			address(token),
			abi.encodeWithSelector(token.ownerOf.selector),
			abi.encode(address(0xffff))
		);

		vm.expectCall(
			address(token),
			abi.encodeWithSelector(token.ownerOf.selector, id)
		);
		uint256 balance = MultiToken.balanceOf(
			MultiToken.Asset(MultiToken.Category.ERC721, address(token), id, 1),
			target
		);
		assertEq(balance, 0);
	}

	function test_shouldReturnBalance_whenERC1155() external {
		IERC1155 token = IERC1155(address(0xa66e7));
		address target = address(0xb0b);
		uint256 id = 330022;
		uint256 balanceMock = 101e18;

		vm.etch(address(token), bytes("0x01"));
		vm.mockCall(
			address(token),
			abi.encodeWithSelector(token.balanceOf.selector),
			abi.encode(balanceMock)
		);

		vm.expectCall(
			address(token),
			abi.encodeWithSelector(token.balanceOf.selector, target, id)
		);
		uint256 balance = MultiToken.balanceOf(
			MultiToken.Asset(MultiToken.Category.ERC1155, address(token), id, 10e18),
			target
		);
		assertEq(balance, balanceMock);
	}

}


/*----------------------------------------------------------*|
|*  # APPROVE ASSET                                         *|
|*----------------------------------------------------------*/

contract MultiToken_ApproveAsset_Test is Test {

	function test_shouldCallApprove_whenERC20() external {
		IERC20 token = IERC20(address(0xa66e7));
		address recipient = address(0xb0b);
		uint256 amount = 101e18;

		vm.etch(address(token), bytes("0x01"));
		vm.mockCall(
			address(token),
			abi.encodeWithSelector(token.approve.selector),
			abi.encode(true)
		);

		vm.expectCall(
			address(token),
			abi.encodeWithSelector(token.approve.selector, recipient, amount)
		);
		MultiToken.approveAsset(
			MultiToken.Asset(MultiToken.Category.ERC20, address(token), 0, amount),
			recipient
		);
	}

	function test_shouldCallApprove_whenERC721() external {
		IERC721 token = IERC721(address(0xa66e7));
		address recipient = address(0xb0b);
		uint256 id = 9973;

		vm.etch(address(token), bytes("0x01"));

		vm.expectCall(
			address(token),
			abi.encodeWithSelector(token.approve.selector, recipient, id)
		);
		MultiToken.approveAsset(
			MultiToken.Asset(MultiToken.Category.ERC721, address(token), id, 1),
			recipient
		);
	}

	function test_shouldCallSetApprovalForAll_whenERC1155() external {
		IERC721 token = IERC721(address(0xa66e7));
		address recipient = address(0xb0b);
		uint256 id = 9973;
		uint256 amount = 333e18;

		vm.etch(address(token), bytes("0x01"));

		vm.expectCall(
			address(token),
			abi.encodeWithSelector(token.setApprovalForAll.selector, recipient, true)
		);
		MultiToken.approveAsset(
			MultiToken.Asset(MultiToken.Category.ERC1155, address(token), id, amount),
			recipient
		);
	}

}


/*----------------------------------------------------------*|
|*  # IS VALID                                              *|
|*----------------------------------------------------------*/

contract MultiToken_IsValid_Test is Test {

	function test_shouldFail_whenERC20WithNonZeroId() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC20, address(0xa66e7), 6362, 100e18)
		);

		assertEq(isValid, false);
	}

	function test_shouldFail_whenERC20WithZeroAmount() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC20, address(0xa66e7), 0, 0)
		);

		assertEq(isValid, false);
	}

	function test_shouldFail_whenERC721WithZeroAmount() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 323, 0)
		);

		assertEq(isValid, false);
	}

	function test_shouldFail_whenERC721WithAmountBiggerThan1() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 323, 2)
		);

		assertEq(isValid, false);
	}

	function test_shouldFail_whenERC1155WithZeroAmount() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC1155, address(0xa66e7), 323, 0)
		);

		assertEq(isValid, false);
	}

	function test_shouldPass_whenValidERC20() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC20, address(0xa66e7), 0, 213)
		);

		assertEq(isValid, true);
	}

	function test_shouldPass_whenValidERC721() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC721, address(0xa66e7), 323, 1)
		);

		assertEq(isValid, true);
	}

	function test_shouldPass_whenValidERC1155() external {
		bool isValid = MultiToken.isValid(
			MultiToken.Asset(MultiToken.Category.ERC1155, address(0xa66e7), 323, 213)
		);

		assertEq(isValid, true);
	}

}


/*----------------------------------------------------------*|
|*  # IS SAME AS                                            *|
|*----------------------------------------------------------*/

contract MultiToken_IsSameAs_Test is Test {

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
