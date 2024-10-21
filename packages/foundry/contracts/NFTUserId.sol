// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTUserIdentification is ERC721, Ownable {
    mapping(address => uint256[]) private address2TokenIds;

    constructor (
        address owner, 
        string memory name, 
        string memory symbol) 
        ERC721(name, symbol) 
        Ownable(owner) 
    {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        address2TokenIds[to].push(tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
        _beforeTokenTransfer(msg.sender, address(0), tokenId);
    }

    function addressTokenIds(address owner) public returns (uint256[] memory) {
        return address2TokenIds[owner];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {
        if (from != address(0)) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        address2TokenIds[from].push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIdx = address2TokenIds[from].length - 1;
        uint256 tokenIdx; 

        for (uint256 i = 0; i < address2TokenIds[from].length; i++) {
            if (address2TokenIds[from][i] == tokenId) {
                tokenIdx = i;
                break;
            }
        }

        if (tokenIdx != lastTokenIdx) {
            uint256 lastTokenId = address2TokenIds[from][lastTokenIdx];
            address2TokenIds[from][tokenIdx] = lastTokenId;
        }

        address2TokenIds[from].pop();
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }

        _beforeTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal override {
       super._safeTransfer(from, to, tokenId, "");
        _beforeTokenTransfer(from, to, tokenId);
    }
}