// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IPermit2Like {

    /**
     * @notice Transfer approved tokens from one address to another
     * @dev Requires the from address to have approved at least the desired amount of tokens to msg.sender.
     * @param from The address to transfer from
     * @param to The address of the recipient
     * @param amount The amount of the token to transfer
     * @param token The token address to transfer
     */
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /**
     * @notice Approves the spender to use up to amount of the specified token up until the expiration
     * @param token The token to approve
     * @param spender The spender address to approve
     * @param amount The approved amount of the token
     * @param expiration The timestamp at which the approval is no longer valid
     * @dev The packed allowance also holds a nonce, which will stay unchanged in approve
     * @dev Setting amount to type(uint160).max sets an unlimited approval
     */
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

}
