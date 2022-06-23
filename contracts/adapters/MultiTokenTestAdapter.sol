// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../MultiToken.sol";

contract MultiTokenTestAdapter {
	using MultiToken for MultiToken.Asset;


	function transferAsset(address _assetAddress, MultiToken.Category _category, uint256 _amount, uint256 _id, address _destination) external {
		MultiToken.Asset(_assetAddress, _category, _amount, _id).transferAsset(_destination);
	}

	function transferAssetFrom(address _assetAddress, MultiToken.Category _category, uint256 _amount, uint256 _id, address _source, address _destination) external {
		MultiToken.Asset(_assetAddress, _category, _amount, _id).transferAssetFrom(_source, _destination);
	}

	function permit(address _assetAddress, MultiToken.Category _category, uint256 _amount, uint256 _id, address _owner, address _spender, bytes memory _permit) external {
		MultiToken.Asset(_assetAddress, _category, _amount, _id).permit(_owner, _spender, _permit);
	}

	function balanceOf(address _assetAddress, MultiToken.Category _category, uint256 _amount, uint256 _id, address _target) external view returns (uint256) {
		return MultiToken.Asset(_assetAddress, _category, _amount, _id).balanceOf(_target);
	}

	function approveAsset(address _assetAddress, MultiToken.Category _category, uint256 _amount, uint256 _id, address _target) external {
		MultiToken.Asset(_assetAddress, _category, _amount, _id).approveAsset(_target);
	}

	function isValid(address _assetAddress, MultiToken.Category _category, uint256 _amount, uint256 _id) external pure returns (bool) {
		return MultiToken.Asset(_assetAddress, _category, _amount, _id).isValid();
	}

	function isSameAs(
		address _assetAddress1, MultiToken.Category _category1, uint256 _amount1, uint256 _id1,
		address _assetAddress2, MultiToken.Category _category2, uint256 _amount2, uint256 _id2
	) external pure returns (bool) {
		return MultiToken.Asset(_assetAddress1, _category1, _amount1, _id1)
			.isSameAs(MultiToken.Asset(_assetAddress2, _category2, _amount2, _id2));
	}

}
