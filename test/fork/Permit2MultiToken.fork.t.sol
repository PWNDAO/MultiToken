// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Test } from "forge-std/Test.sol";

import {
    Permit2MultiToken, Asset, Category,
    IERC20, IPermit2Like
} from "multitoken/Permit2MultiToken.sol";

using Permit2MultiToken for address;
using Permit2MultiToken for Asset;

abstract contract Permit2MultiTokenIntegrationTest is Test {

    // Mainnet addresses
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    address joey;
    uint256 joeyPK;
    address chandler;
    uint256 chandlerPK;
    uint160 amount = 1 ether;

    function setUp() public virtual {
        vm.createSelectFork("mainnet");

        (joey, joeyPK) = makeAddrAndKey("joey");
        (chandler, chandlerPK) = makeAddrAndKey("chandler");

        vm.label(WETH, "WETH");
        vm.label(address(permit2), "Permit2");
    }

}


/*----------------------------------------------------------*|
|*  # TRANSFER                                              *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_Transfer_IntegrationTest is Permit2MultiTokenIntegrationTest {

    function test_shouldUsePermit2ToTransferERC20() external {
        assertEq(IERC20(WETH).balanceOf(joey), 0);
        assertEq(IERC20(WETH).balanceOf(chandler), 0);

        vm.prank(WETH); // Assuming WETH contract has at least `amount` tokens
        (bool success, ) = WETH.call(abi.encodeWithSignature("transfer(address,uint256)", joey, amount));
        require(success, "WETH initial test token transfer failed");

        vm.startPrank(joey);
        IERC20(WETH).approve(permit2, type(uint256).max);
        IPermit2Like(permit2).approve(WETH, chandler, amount, uint48(block.timestamp + 1 days));
        vm.stopPrank();

        vm.expectCall(
            permit2,
            abi.encodeWithSelector(IPermit2Like.transferFrom.selector, joey, chandler, amount / 2, WETH)
        );

        vm.prank(chandler);
        WETH.ERC20(amount / 2).transferAssetFrom(permit2, joey, chandler);

        assertEq(IERC20(WETH).balanceOf(joey), amount / 2);
        assertEq(IERC20(WETH).balanceOf(chandler), amount / 2);

        vm.warp(block.timestamp + 0.5 days);

        vm.prank(chandler);
        WETH.ERC20(amount / 2).transferAssetFrom(permit2, joey, chandler);

        assertEq(IERC20(WETH).balanceOf(joey), 0);
        assertEq(IERC20(WETH).balanceOf(chandler), amount);
    }

}


/*----------------------------------------------------------*|
|*  # PERMIT TRANSFER                                       *|
|*----------------------------------------------------------*/

contract Permit2MultiToken_PermitTransfer_IntegrationTest is Permit2MultiTokenIntegrationTest {

    function _sign(uint256 pk, bytes32 _hash) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, _hash);
        return abi.encodePacked(r, s, v);
    }


    function test_shouldUsePermit2ToTransferERC20() external {
        assertEq(IERC20(WETH).balanceOf(joey), 0);
        assertEq(IERC20(WETH).balanceOf(chandler), 0);

        vm.prank(WETH); // Assuming WETH contract has at least `amount` tokens
        (bool success, ) = WETH.call(abi.encodeWithSignature("transfer(address,uint256)", joey, amount));
        require(success, "WETH initial test token transfer failed");

        vm.prank(joey);
        IERC20(WETH).approve(permit2, type(uint256).max);

        IPermit2Like.PermitTransferFrom memory permit = IPermit2Like.PermitTransferFrom({
            permitted: IPermit2Like.TokenPermissions(WETH, amount),
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 tokenPermissionsHash = keccak256(abi.encode(
            keccak256("TokenPermissions(address token,uint256 amount)"),
            permit.permitted
        ));
        bytes32 permitHash = keccak256(abi.encode(
            keccak256("PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"),
            tokenPermissionsHash, chandler, permit.nonce, permit.deadline
        ));
        bytes32 domainSeparator = IPermit2Like(permit2).DOMAIN_SEPARATOR();
        bytes memory signature = _sign(
            joeyPK,
            keccak256(abi.encodePacked(hex"1901", domainSeparator, permitHash))
        );

        vm.expectCall(
            permit2,
            abi.encodeWithSelector(IPermit2Like.permitTransferFrom.selector)
        );

        vm.prank(chandler);
        WETH.ERC20(amount / 2).permitTransferAssetFrom(permit2, joey, chandler, permit, signature);

        assertEq(IERC20(WETH).balanceOf(joey), amount / 2);
        assertEq(IERC20(WETH).balanceOf(chandler), amount / 2);

        // Note: can use permit only once
    }

}
