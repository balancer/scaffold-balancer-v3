// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NFTMetadata is Ownable {
    using Strings for uint256;

    mapping(uint256 => string) private _tierNames;
    mapping(uint256 => string) private _tierColors;

    constructor() Ownable(msg.sender) {
        _tierNames[1] = "Bronze";
        _tierNames[2] = "Silver";
        _tierNames[3] = "Gold";
        
        _tierColors[1] = "#CD7F32";
        _tierColors[2] = "#C0C0C0";
        _tierColors[3] = "#FFD700";
    }

    function setTierName(uint256 tier, string memory name) external onlyOwner {
        _tierNames[tier] = name;
    }

    function setTierColor(uint256 tier, string memory color) external onlyOwner {
        _tierColors[tier] = color;
    }

    function generateImage(uint256 tier) internal view returns (string memory) {
        string memory color = _tierColors[tier];
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350">',
            '<rect width="100%" height="100%" fill="', color, '" />',
            '<text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="white" font-size="24">',
            _tierNames[tier],
            ' Tier</text>',
            '</svg>'
        ));
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }

    function tokenURI(uint256 tokenId, uint256 tier) external view returns (string memory) {
        string memory name = string(abi.encodePacked("Liquidity Staking NFT - ", _tierNames[tier]));
        string memory description = string(abi.encodePacked("This NFT represents a ", _tierNames[tier], " tier liquidity staking position"));
        string memory image = generateImage(tier);

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', name, '",',
                            '"description":"', description, '",',
                            '"image":"', image, '",',
                            '"attributes":[{"trait_type":"Tier","value":"', _tierNames[tier], '"}]}'
                        )
                    )
                )
            )
        );

    }
}