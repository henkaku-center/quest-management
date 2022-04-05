//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => string[]) private _communityRoles;

    constructor() ERC721("Henkaku v0.1", "henkaku") {}

    function getCommuinityMemberRole(address _address)
        public
        view
        returns (string[] memory)
    {
        return _communityRoles[_address];
    }

    function hasRoleOf(address _address, string memory _role)
        public
        view
        returns (bool)
    {
        string[] memory _roles = _communityRoles[_address];
        for (uint256 i = 0; i < _roles.length; i++) {
            if (keccak256(bytes(_roles[i])) == keccak256(bytes(_role))) {
                return true;
            }
        }
        return false;
    }

    function mint(string[] memory _roles, address _to)
        public
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);

        for (uint256 i = 0; i < _roles.length; i++) {
            _communityRoles[_to].push(_roles[i]);
        }

        string memory finalTokenUri = "https://example.com/";
        _setTokenURI(newItemId, finalTokenUri);
        return newItemId;
    }
}
