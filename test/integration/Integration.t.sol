// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "@openzeppelin/interfaces/IERC20.sol";
import "@openzeppelin/interfaces/IERC721.sol";
import "@openzeppelin/interfaces/IERC1155.sol";
import "@openzeppelin/token/ERC1155/ERC1155.sol";
import "@openzeppelin/token/ERC20/extensions/draft-IERC20Permit.sol";

import "@MT/interfaces/ICryptoKitties.sol";
import "@MT/MultiToken.sol";


abstract contract MultiTokenIntegrationTest is Test {

    // Mainnet addresses
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address BNB = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address CK = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d; // CryptoKitties
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DOODLE = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e; // Doodles

    uint256 joeyKey;
    address joey;
    uint256 chandlerKey;
    address chandler;

    uint256 amount = 101;
    uint256 id = 755;

    function setUp() public virtual {
        vm.createSelectFork("mainnet");

        (joey, joeyKey) = makeAddrAndKey("joey");
        (chandler, chandlerKey) = makeAddrAndKey("chandler");
    }

}

contract T1155 is ERC1155("test") {

    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount, "");
    }

}


/*----------------------------------------------------------*|
|*  # TRANSFER                                              *|
|*----------------------------------------------------------*/

contract MultiToken_Transfer_IntegrationTest is MultiTokenIntegrationTest {
    using MultiToken for MultiToken.Asset;

    // ERC20

    function test_transferERC20_whenCallerIsSource() external {
        bool success;

        // WETH - transfer & transferFrom returning bool
        vm.prank(WETH); // Assuming WETH contract has at least `amount` tokens
        (success, ) = WETH.call(abi.encodeWithSignature("transfer(address,uint256)", address(this), amount));
        require(success, "WETH initial test token transfer failed");

        assertEq(IERC20(WETH).balanceOf(address(this)), amount);
        assertEq(IERC20(WETH).balanceOf(chandler), 0);

        vm.expectCall(
            WETH,
            abi.encodeWithSignature("transfer(address,uint256)", chandler, amount)
        );
        MultiToken.Asset(MultiToken.Category.ERC20, WETH, 0, amount).transferAssetFrom({
            source: address(this),
            dest: chandler
        });

        assertEq(IERC20(WETH).balanceOf(address(this)), 0);
        assertEq(IERC20(WETH).balanceOf(chandler), amount);


        // BNB - transfer not returning bool
        vm.prank(BNB); // Assuming BNB contract has at least `amount` tokens
        (success, ) = BNB.call(abi.encodeWithSignature("transfer(address,uint256)", address(this), amount));
        require(success, "BNB initial test token transfer failed");

        assertEq(IERC20(BNB).balanceOf(address(this)), amount);
        assertEq(IERC20(BNB).balanceOf(chandler), 0);

        vm.expectCall(
            BNB,
            abi.encodeWithSignature("transfer(address,uint256)", chandler, amount)
        );
        MultiToken.Asset(MultiToken.Category.ERC20, BNB, 0, amount).transferAssetFrom({
            source: address(this),
            dest: chandler
        });

        assertEq(IERC20(BNB).balanceOf(address(this)), 0);
        assertEq(IERC20(BNB).balanceOf(chandler), amount);


        // USDT - transfer & transferFrom not returning bool
        address TetherTreasury = 0x5754284f345afc66a98fbB0a0Afe71e0F007B949;
        vm.prank(TetherTreasury); // Assuming Tether treasury contract has at least `amount` tokens
        (success, ) = USDT.call(abi.encodeWithSignature("transfer(address,uint256)", address(this), amount));
        require(success, "USDT initial test token transfer failed");

        assertEq(IERC20(USDT).balanceOf(address(this)), amount);
        assertEq(IERC20(USDT).balanceOf(chandler), 0);

        vm.expectCall(
            USDT,
            abi.encodeWithSignature("transfer(address,uint256)", chandler, amount)
        );
        MultiToken.Asset(MultiToken.Category.ERC20, USDT, 0, amount).transferAssetFrom({
            source: address(this),
            dest: chandler
        });

        assertEq(IERC20(USDT).balanceOf(address(this)), 0);
        assertEq(IERC20(USDT).balanceOf(chandler), amount);
    }

    function test_transferERC20_whenCallerIsNotSource() external {
        bool success;
        MultiToken.Asset memory asset;

        // WETH - transfer & transferFrom returning bool
        vm.prank(WETH); // Assuming WETH contract has at least `amount` tokens
        (success, ) = WETH.call(abi.encodeWithSignature("transfer(address,uint256)", chandler, amount));
        require(success, "WETH initial test token transfer failed");

        assertEq(IERC20(WETH).balanceOf(chandler), amount);
        assertEq(IERC20(WETH).balanceOf(joey), 0);

        asset = MultiToken.Asset(MultiToken.Category.ERC20, WETH, 0, amount);

        vm.startPrank(chandler); // `safeApprove` is calling `allowance` getter before setting it
        asset.approveAsset(address(this));
        vm.stopPrank();

        vm.expectCall(
            WETH,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", chandler, joey, amount)
        );
        asset.transferAssetFrom({
            source: chandler,
            dest: joey
        });

        assertEq(IERC20(WETH).balanceOf(chandler), 0);
        assertEq(IERC20(WETH).balanceOf(joey), amount);


        // BNB - transfer not returning bool
        vm.prank(BNB); // Assuming BNB contract has at least `amount` tokens
        (success, ) = BNB.call(abi.encodeWithSignature("transfer(address,uint256)", chandler, amount));
        require(success, "BNB initial test token transfer failed");

        assertEq(IERC20(BNB).balanceOf(chandler), amount);
        assertEq(IERC20(BNB).balanceOf(joey), 0);

        asset = MultiToken.Asset(MultiToken.Category.ERC20, BNB, 0, amount);

        vm.startPrank(chandler); // `safeApprove` is calling `allowance` getter before setting it
        asset.approveAsset(address(this));
        vm.stopPrank();

        vm.expectCall(
            BNB,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", chandler, joey, amount)
        );
        asset.transferAssetFrom({
            source: chandler,
            dest: joey
        });

        assertEq(IERC20(BNB).balanceOf(chandler), 0);
        assertEq(IERC20(BNB).balanceOf(joey), amount);


        // USDT - transfer & transferFrom not returning bool
        address TetherTreasury = 0x5754284f345afc66a98fbB0a0Afe71e0F007B949;
        vm.prank(TetherTreasury); // Assuming Tether treasury contract has at least `amount` tokens
        (success, ) = USDT.call(abi.encodeWithSignature("transfer(address,uint256)", chandler, amount));
        require(success, "USDT initial test token transfer failed");

        assertEq(IERC20(USDT).balanceOf(chandler), amount);
        assertEq(IERC20(USDT).balanceOf(joey), 0);

        asset = MultiToken.Asset(MultiToken.Category.ERC20, USDT, 0, amount);

        vm.startPrank(chandler); // `safeApprove` is calling `allowance` getter before setting it
        asset.approveAsset(address(this));
        vm.stopPrank();

        vm.expectCall(
            USDT,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", chandler, joey, amount)
        );
        asset.transferAssetFrom({
            source: chandler,
            dest: joey
        });

        assertEq(IERC20(USDT).balanceOf(chandler), 0);
        assertEq(IERC20(USDT).balanceOf(joey), amount);
    }

    // ERC721

    function test_transferERC721_whenSafeTransfer() external {
        address trueOwner = IERC721(DOODLE).ownerOf(id);
        vm.prank(trueOwner);
        IERC721(DOODLE).transferFrom(trueOwner, address(this), id);

        assertEq(IERC721(DOODLE).ownerOf(id), address(this));

        vm.expectCall(
            DOODLE,
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", address(this), joey, id, "")
        );
        MultiToken.Asset(MultiToken.Category.ERC721, DOODLE, id, 0).safeTransferAssetFrom({
            source: address(this),
            dest: joey
        });

        assertEq(IERC721(DOODLE).ownerOf(id), joey);
    }

    function test_transferERC721_whenNotSafeTransfer() external {
        address trueOwner = IERC721(DOODLE).ownerOf(id);
        vm.prank(trueOwner);
        IERC721(DOODLE).transferFrom(trueOwner, address(this), id);

        assertEq(IERC721(DOODLE).ownerOf(id), address(this));

        vm.expectCall(
            DOODLE,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), joey, id)
        );
        MultiToken.Asset(MultiToken.Category.ERC721, DOODLE, id, 0).transferAssetFrom({
            source: address(this),
            dest: joey
        });

        assertEq(IERC721(DOODLE).ownerOf(id), joey);
    }

    // ERC1155

    function test_transferERC1155_whenAmountIsZero() external {
        T1155 t1155 = new T1155();
        t1155.mint(chandler, id, amount);

        MultiToken.Asset memory asset = MultiToken.Asset(MultiToken.Category.ERC1155, address(t1155), id, 0);

        vm.prank(chandler);
        asset.approveAsset(address(this));

        assertEq(t1155.balanceOf(chandler, id), amount);
        assertEq(t1155.balanceOf(joey, id), 0);

        vm.expectCall(
            address(t1155),
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", chandler, joey, id, 1, "")
        );
        asset.safeTransferAssetFrom({
            source: chandler,
            dest: joey
        });

        assertEq(t1155.balanceOf(chandler, id), amount - 1);
        assertEq(t1155.balanceOf(joey, id), 1);
    }

    function test_transferERC1155_whenAmountIsNotZero() external {
        T1155 t1155 = new T1155();
        t1155.mint(chandler, id, amount);

        MultiToken.Asset memory asset = MultiToken.Asset(MultiToken.Category.ERC1155, address(t1155), id, amount);

        vm.prank(chandler);
        asset.approveAsset(address(this));

        assertEq(t1155.balanceOf(chandler, id), amount);
        assertEq(t1155.balanceOf(joey, id), 0);

        vm.expectCall(
            address(t1155),
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", chandler, joey, id, amount, "")
        );
        asset.safeTransferAssetFrom({
            source: chandler,
            dest: joey
        });

        assertEq(t1155.balanceOf(chandler, id), 0);
        assertEq(t1155.balanceOf(joey, id), amount);
    }

    // CryptoKitties

    function test_transferCryptoKitties_whenCallerIsSource() external {
        address trueOwner = ICryptoKitties(CK).ownerOf(id);
        vm.prank(trueOwner);
        ICryptoKitties(CK).transfer(address(this), id);

        assertEq(ICryptoKitties(CK).ownerOf(id), address(this));

        vm.expectCall(
            CK,
            abi.encodeWithSignature("transfer(address,uint256)", joey, id)
        );
        MultiToken.Asset(MultiToken.Category.CryptoKitties, CK, id, 0).transferAssetFrom({
            source: address(this),
            dest: joey
        });

        assertEq(ICryptoKitties(CK).ownerOf(id), joey);
    }

    function test_transferCryptoKitties_whenCallerIsNotSource() external {
        MultiToken.Asset memory asset = MultiToken.Asset(MultiToken.Category.CryptoKitties, CK, id, 0);
        address trueOwner = ICryptoKitties(CK).ownerOf(id);
        vm.prank(trueOwner);
        ICryptoKitties(CK).transfer(chandler, id);

        assertEq(ICryptoKitties(CK).ownerOf(id), chandler);

        vm.prank(chandler);
        asset.approveAsset(address(this));

        vm.expectCall(
            CK,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", chandler, joey, id)
        );
        asset.transferAssetFrom({
            source: chandler,
            dest: joey
        });

        assertEq(ICryptoKitties(CK).ownerOf(id), joey);
    }

}


/*----------------------------------------------------------*|
|*  # PERMIT                                                *|
|*----------------------------------------------------------*/

contract MultiToken_Permit_IntegrationTest is MultiTokenIntegrationTest {
    using MultiToken for MultiToken.Asset;


    function _signPermit() private returns (uint8 v, bytes32 r, bytes32 s) {
        address mainnetHolder = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;
        vm.prank(mainnetHolder);
        IERC20(USDC).transfer(chandler, amount);

        assertEq(IERC20(USDC).balanceOf(chandler), amount);
        assertEq(IERC20(USDC).balanceOf(joey), 0);

        bytes32 permitHash = keccak256(abi.encodePacked(
            hex"1901",
            IERC20Permit(USDC).DOMAIN_SEPARATOR(),
            keccak256(abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                chandler,
                address(this),
                amount,
                IERC20Permit(USDC).nonces(chandler),
                2 * block.timestamp
            ))
        ));
        (v, r, s) = vm.sign(chandlerKey, permitHash);
    }

    function test_permitAllowance_whenValidSignature() external {
        (uint8 v, bytes32 r, bytes32 s) = _signPermit();

        bytes memory permitData = abi.encodePacked(2 * block.timestamp, r, s, v);

        MultiToken.Asset(MultiToken.Category.ERC20, USDC, 0, amount).permit(chandler, address(this), permitData);

        IERC20(USDC).transferFrom(chandler, joey, amount);

        assertEq(IERC20(USDC).balanceOf(chandler), 0);
        assertEq(IERC20(USDC).balanceOf(joey), amount);
    }

    function test_permitAllowance_whenValidCompactSignature() external {
        (uint8 v, bytes32 r, bytes32 s) = _signPermit();

        bytes32 vs = bytes32(uint256(v - 27) << 255) | s;
        bytes memory permitData = abi.encodePacked(2 * block.timestamp, r, vs);

        MultiToken.Asset(MultiToken.Category.ERC20, USDC, 0, amount).permit(chandler, address(this), permitData);

        IERC20(USDC).transferFrom(chandler, joey, amount);

        assertEq(IERC20(USDC).balanceOf(chandler), 0);
        assertEq(IERC20(USDC).balanceOf(joey), amount);
    }

}


/*----------------------------------------------------------*|
|*  # APPROVE                                               *|
|*----------------------------------------------------------*/

contract MultiToken_Approve_IntegrationTest is MultiTokenIntegrationTest {
    using MultiToken for MultiToken.Asset;


    function test_approveAmount_whenERC20() external {
        address mainnetHolder = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;
        vm.prank(mainnetHolder);
        IERC20(USDC).transfer(chandler, amount);

        assertEq(IERC20(USDC).allowance(chandler, joey), 0);

        vm.startPrank(chandler); // `safeApprove` is calling `allowance` getter before setting it
        MultiToken.Asset(MultiToken.Category.ERC20, USDC, 0, amount).approveAsset(joey);
        vm.stopPrank();

        assertEq(IERC20(USDC).allowance(chandler, joey), amount);
    }

    function test_approveId_whenERC721() external {
        address trueOwner = IERC721(DOODLE).ownerOf(id);
        vm.prank(trueOwner);
        IERC721(DOODLE).transferFrom(trueOwner, chandler, id);

        assertEq(IERC721(DOODLE).getApproved(id), address(0));

        vm.prank(chandler);
        MultiToken.Asset(MultiToken.Category.ERC721, DOODLE, id, 0).approveAsset(joey);

        assertEq(IERC721(DOODLE).getApproved(id), joey);
    }

    function test_approveAll_whenERC1155() external {
        T1155 t1155 = new T1155();
        t1155.mint(chandler, id, amount);

        assertEq(t1155.isApprovedForAll(chandler, joey), false);

        vm.prank(chandler);
        MultiToken.Asset(MultiToken.Category.ERC1155, address(t1155), id, amount).approveAsset(joey);

        assertEq(t1155.isApprovedForAll(chandler, joey), true);
    }

    // CryptoKitties doesn't implement `getApproved` function. The approve is tested by a transfer.
    function test_approveId_whenCryptoKitties() external {
        MultiToken.Asset memory asset = MultiToken.Asset(MultiToken.Category.CryptoKitties, CK, id, 0);
        address trueOwner = ICryptoKitties(CK).ownerOf(id);
        vm.prank(trueOwner);
        ICryptoKitties(CK).transfer(chandler, id);

        vm.expectRevert();
        vm.prank(joey);
        asset.transferAssetFrom(chandler, joey);

        assertEq(ICryptoKitties(CK).ownerOf(id), chandler);

        vm.prank(chandler);
        asset.approveAsset(joey);

        vm.prank(joey);
        asset.transferAssetFrom(chandler, joey);

        assertEq(ICryptoKitties(CK).ownerOf(id), joey);
    }

}


/*----------------------------------------------------------*|
|*  # IS VALID                                              *|
|*----------------------------------------------------------*/

contract MultiToken_IsValid_IntegrationTest is MultiTokenIntegrationTest {
    using MultiToken for MultiToken.Asset;

    address t1155;

    function setUp() override public {
        super.setUp();

        t1155 = address(new T1155());
    }

    // ERC20

    function test_returnTrue_whenValidERC20() external {
        assertTrue(
            MultiToken.Asset(MultiToken.Category.ERC20, USDC, 0, amount).isValid()
        );
    }

    function test_returnFalse_whenERC20_withNonZeroId() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC20, USDC, id, amount).isValid()
        );
    }

    function test_returnFalse_whenERC20_withERC721Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC721, USDC, id, 0).isValid()
        );
    }

    function test_returnFalse_whenERC20_withERC1155Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC1155, USDC, id, amount).isValid()
        );
    }

    function test_returnFalse_whenERC20_withCryptoKittiesCategory() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.CryptoKitties, USDC, id, 0).isValid()
        );
    }

    // ERC721

    function test_returnTrue_whenValidERC721() external {
        assertTrue(
            MultiToken.Asset(MultiToken.Category.ERC721, DOODLE, id, 0).isValid()
        );
    }

    function test_returnFalse_whenERC721_withNonZeroAmount() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC721, DOODLE, id, 1).isValid()
        );
    }

    function test_returnFalse_whenERC721_withERC20Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC20, DOODLE, 0, amount).isValid()
        );
    }

    function test_returnFalse_whenERC721_withERC1155Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC1155, DOODLE, id, amount).isValid()
        );
    }

    function test_returnFalse_whenERC721_withCryptoKittiesCategory() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.CryptoKitties, DOODLE, id, 0).isValid()
        );
    }

    // ERC1155

    function test_returnTrue_whenValidERC1155() external {
        assertTrue(
            MultiToken.Asset(MultiToken.Category.ERC1155, t1155, id, amount).isValid()
        );
    }

    function test_returnFalse_whenERC1155_withERC20Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC20, t1155, 0, amount).isValid()
        );
    }

    function test_returnFalse_whenERC1155_withERC721Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC721, t1155, id, 0).isValid()
        );
    }

    function test_returnFalse_whenERC1155_withCryptoKittiesCategory() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.CryptoKitties, t1155, id, 0).isValid()
        );
    }

    // CryptoKitties

    function test_returnTrue_whenValidCryptoKitties() external {
        assertTrue(
            MultiToken.Asset(MultiToken.Category.CryptoKitties, CK, id, 0).isValid()
        );
    }

    function test_returnFalse_whenCryptoKitties_withNonZeroAmount() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.CryptoKitties, CK, id, 1).isValid()
        );
    }

    function test_returnFalse_whenCryptoKitties_withERC20Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC20, CK, 0, amount).isValid()
        );
    }

    function test_returnFalse_whenCryptoKitties_withERC721Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC721, CK, id, 0).isValid()
        );
    }

    function test_returnFalse_whenCryptoKitties_withERC1155Category() external {
        assertFalse(
            MultiToken.Asset(MultiToken.Category.ERC1155, CK, id, amount).isValid()
        );
    }

}
