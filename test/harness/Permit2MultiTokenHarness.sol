// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Permit2MultiToken, Asset, IPermit2Like } from "multitoken/Permit2MultiToken.sol";


contract Permit2MultiTokenHarness {

    function transferAssetFrom(Asset memory asset, address permit2, address source, address dest) external {
        Permit2MultiToken.transferAssetFrom(asset, permit2, source, dest);
    }

    function permitTransferAssetFrom(
        Asset memory asset,
        address permit2,
        address source,
        address dest,
        IPermit2Like.PermitTransferFrom memory permit,
        bytes memory signature
    ) external {
        Permit2MultiToken.permitTransferAssetFrom(asset, permit2, source, dest, permit, signature);
    }

}
