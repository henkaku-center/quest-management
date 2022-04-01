//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IHenkakuMemberShip {
    function balanceOf(address _owner) external view returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function isCommunityMember(uint256 _tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract HenkakuQuest is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant QUEST_CREATION_ROLE =
        keccak256("QUEST_CREATION_ROLE");
    bytes32 public constant HENKAKU_MEMBER_ROLE =
        keccak256("HENKAKU_MEMBER_ROLE");

    struct Content {
        string title;
        string category;
        string description;
        string limitation;
        uint256 amount;
        uint256 endedAt;
    }

    struct Quest {
        Content jp;
        Content en;
    }

    address private memberShipNFTAddress;
    IHenkakuMemberShip private memberShipNFT;
    mapping(uint256 => Quest) quests;
    uint256 private id;

    constructor(address _memberShipNftAddress) {
        _grantRole(ADMIN_ROLE, msg.sender);
        setNFTAddress(_memberShipNftAddress);
    }

    function setNFTAddress(address _memberShipNftAddress) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "You need to have an admin");
        memberShipNFTAddress = _memberShipNftAddress;
        memberShipNFT = IHenkakuMemberShip(memberShipNFTAddress);
    }

    function addAdminRole(address _to) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You need to have an admin role to add Admin role"
        );
        _grantRole(ADMIN_ROLE, _to);
    }

    function addQuestCreationRole(address _to) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You need to have an admin role to add quest creation role"
        );
        _grantRole(QUEST_CREATION_ROLE, _to);
    }

    function addMemberRole(address _to) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "You need to have an admin role to add quest creation role"
        );
        _grantRole(HENKAKU_MEMBER_ROLE, _to);
    }

    function isMember(address _address) internal view returns (bool) {
        uint256 _balance = memberShipNFT.balanceOf(_address);
        if (_balance <= 0) {
            return false;
        }

        uint256 _tokenId = 0;
        address _candidate;
        bool _isMember = false;
        while (!_isMember) {
            _tokenId += 1;
            _candidate = memberShipNFT.ownerOf(_tokenId);
            _isMember = _candidate == _address;
            console.log(_tokenId);
            console.log(_candidate);
        }
        return memberShipNFT.isCommunityMember(_tokenId);
    }

    function save(Quest memory _quest) public {
        require(
            hasRole(QUEST_CREATION_ROLE, msg.sender) ||
                hasRole(ADMIN_ROLE, msg.sender),
            "You need to have Quest creation role or admin role to add a quest"
        );
        quests[id] = _quest;
        id += 1;
    }

    function canReadQuest(address _address) public view returns (bool) {
        return
            hasRole(QUEST_CREATION_ROLE, _address) ||
            hasRole(ADMIN_ROLE, _address) ||
            hasRole(HENKAKU_MEMBER_ROLE, _address) ||
            isMember(_address);
    }

    function getQuests() public view returns (Quest[] memory) {
        require(canReadQuest(msg.sender), "You dont have permission to obtain");
        Quest[] memory _quests = new Quest[](id);
        for (uint256 i = 0; i < id; i++) {
            _quests[i] = quests[i];
        }

        return _quests;
    }
}
