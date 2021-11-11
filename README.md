# MultiToken library
The library defines a token asset as a struct of token identifiers.
It wraps transfer, allowance & balance check calls of the following token standards:
- ERC20
- ERC721
- ERC1155

Unifying the function calls used within the PWN context (not having to worry about handling those individually).
