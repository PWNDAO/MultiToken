// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IPermit2Like {

    /** @notice The token and amount details for a transfer signed in the permit transfer signature */
    struct TokenPermissions {
        address token;
        uint256 amount;
    }

    /** @notice The signed permit message for a single token transfer */
    struct PermitTransferFrom {
        TokenPermissions permitted;
        uint256 nonce;
        uint256 deadline;
    }

    /**
     * @notice Specifies the recipient address and amount for batched transfers.
     * @dev Recipients and amounts correspond to the index of the signed token permissions array.
     * @dev Reverts if the requested amount is greater than the permitted signed amount.
     */
    struct SignatureTransferDetails {
        address to;
        uint256 requestedAmount;
    }

    /** @notice Returns the domain separator for the current chain. */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Transfers a token using a signed permit message
     * @dev Reverts if the requested amount is greater than the permitted signed amount
     * @param permit The permit data signed over by the owner
     * @param owner The owner of the tokens to transfer
     * @param transferDetails The spender's requested transfer details for the permitted token
     * @param signature The signature to verify
     */
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

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
