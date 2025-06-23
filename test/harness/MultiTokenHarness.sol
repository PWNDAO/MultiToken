// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { MultiToken } from "multitoken/MultiToken.sol";


contract MultiTokenHarness {

    function transferAssetFrom(MultiToken.Asset memory asset, address source, address dest) external {
        MultiToken.transferAssetFrom(asset, source, dest);
    }

    function safeTransferAssetFrom(MultiToken.Asset memory asset, address source, address dest) external {
        MultiToken.safeTransferAssetFrom(asset, source, dest);
    }

    function permit(MultiToken.Asset memory asset, address owner, address spender, bytes memory permitData) external {
        MultiToken.permit(asset, owner, spender, permitData);
    }

}
