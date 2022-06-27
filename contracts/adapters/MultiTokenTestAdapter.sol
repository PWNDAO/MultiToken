// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../MultiToken.sol";

contract MultiTokenTestAdapter {
	using MultiToken for MultiToken.Asset;


	function transferAsset(MultiToken.Category _category, address _assetAddress, uint256 _id, uint256 _amount, address _destination) external {
		MultiToken.Asset(_category, _assetAddress, _id,  _amount).transferAsset(_destination);
	}

	function transferAssetFrom(MultiToken.Category _category, address _assetAddress, uint256 _id, uint256 _amount, address _source, address _destination) external {
		MultiToken.Asset(_category, _assetAddress, _id,  _amount).transferAssetFrom(_source, _destination);
	}

	function permit(MultiToken.Category _category, address _assetAddress, uint256 _id, uint256 _amount, address _owner, address _spender, bytes memory _permit) external {
		MultiToken.Asset(_category, _assetAddress, _id,  _amount).permit(_owner, _spender, _permit);
	}

	function balanceOf(MultiToken.Category _category, address _assetAddress, uint256 _id, uint256 _amount, address _target) external view returns (uint256) {
		return MultiToken.Asset(_category, _assetAddress, _id,  _amount).balanceOf(_target);
	}

	function approveAsset(MultiToken.Category _category, address _assetAddress, uint256 _id, uint256 _amount, address _target) external {
		MultiToken.Asset(_category, _assetAddress, _id,  _amount).approveAsset(_target);
	}

	function isValid(MultiToken.Category _category, address _assetAddress, uint256 _id, uint256 _amount) external pure returns (bool) {
		return MultiToken.Asset(_category, _assetAddress, _id,  _amount).isValid();
	}

	function isSameAs(
		MultiToken.Category _category1, address _assetAddress1, uint256 _id1, uint256 _amount1,
		MultiToken.Category _category2, address _assetAddress2, uint256 _id2, uint256 _amount2
	) external pure returns (bool) {
		return MultiToken.Asset(_category1, _assetAddress1, _id1, _amount1)
			.isSameAs(MultiToken.Asset(_category2, _assetAddress2, _id2, _amount2));
	}

}
