// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Permit20
 * @dev Interface for interacting with assets implementing ERC2612 https://eips.ethereum.org/EIPS/eip-2612 aka signed approvals
 */
interface Permit20 {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
