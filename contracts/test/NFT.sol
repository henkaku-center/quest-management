//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => bool) private _communityMemberShip;

    constructor() ERC721("Henkaku v0.1", "henkaku") {}

    function isCommunityMember(uint256 _tokenId) public view returns(bool) {
      return _communityMemberShip[_tokenId];
    }

    function mint(bool isMember, address _to) public returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_to, newItemId);

        _communityMemberShip[newItemId] = isMember;
        string memory finalTokenUri = "https://example.com/";
        _setTokenURI(newItemId, finalTokenUri);
        return newItemId;
    }

}