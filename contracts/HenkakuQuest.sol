//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IHenkakuMemberShip {
    function balanceOf(address _owner) external view returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function isCommunityMember(uint256 _tokenId) external view returns (bool);

    function getCommuinityMemberRole(address _address) external view returns (string[] memory);

    function hasRoleOf(address _address, string memory _role) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract HenkakuQuest is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant QUEST_CREATION_ROLE =
        keccak256("QUEST_CREATION_ROLE");
    bytes32 public constant HENKAKU_MEMBER_ROLE =
        keccak256("HENKAKU_MEMBER_ROLE");

    struct Billingual {
        string jp;
        string en;
    }

    struct Quest {
        Billingual title;
        Billingual description;
        string category;
        string limitation;
        uint256 amount;
        uint256 endedAt;
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

    function hasRoleOf(
        address _address,
        bytes32 _role,
        string memory _nftRole
    ) internal view returns (bool) {
        if (hasRole(_role, _address)) {
            return true;
        }

        uint256 _balance = memberShipNFT.balanceOf(_address);
        if (_balance <= 0) {
            return false;
        }
        return memberShipNFT.hasRoleOf(_address, _nftRole);
    }

    function hasAdminRole(address _address) internal view returns (bool) {
        return hasRoleOf(_address, ADMIN_ROLE, "ADMIN_ROLE");
    }

    function hasCreatQuestRole(address _address) internal view returns (bool) {
        return hasRoleOf(_address, QUEST_CREATION_ROLE, "QUEST_CREATION_ROLE");
    }

    function hasMemberRole(address _address) internal view returns (bool) {
        return hasRoleOf(_address, HENKAKU_MEMBER_ROLE, "MEMBER_ROLE");
    }

    function closeQuest(uint256 _id) public {
        require(
            hasCreatQuestRole(msg.sender) || hasAdminRole(msg.sender),
            "You need to have Quest creation role or admin role to edit a quest"
        );
        Quest memory _quest = quests[_id];
        _quest.endedAt = block.timestamp;
        quests[_id] = _quest;
    }

    function update(uint256 _id, Quest memory _quest) public {
        require(
            hasCreatQuestRole(msg.sender) || hasAdminRole(msg.sender),
            "You need to have Quest creation role or admin role to edit a quest"
        );
        quests[_id] = _quest;
    }

    function save(Quest memory _quest) public {
        require(
            hasCreatQuestRole(msg.sender) || hasAdminRole(msg.sender),
            "You need to have Quest creation role or admin role to add a quest"
        );
        quests[id] = _quest;
        id += 1;
    }

    function canReadQuest(address _address) public view returns (bool) {
        return
            hasMemberRole(_address) ||
            hasCreatQuestRole(_address) ||
            hasAdminRole(_address);
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
