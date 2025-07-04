// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Permit2MultiToken, Asset } from "multitoken/Permit2MultiToken.sol";


contract Permit2MultiTokenHarness {

    function transferAssetFrom(Asset memory asset, address permit2, address source, address dest) external {
        Permit2MultiToken.transferAssetFrom(asset, permit2, source, dest);
    }

    function safeTransferAssetFrom(Asset memory asset, address permit2, address source, address dest) external {
        Permit2MultiToken.safeTransferAssetFrom(asset, permit2, source, dest);
    }

}
