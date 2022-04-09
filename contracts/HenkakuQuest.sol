//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IHenkakuMemberShip {
    function balanceOf(address _owner) external view returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function isCommunityMember(uint256 _tokenId) external view returns (bool);

    function getCommuinityMemberRole(address _address)
        external
        view
        returns (string[] memory);

    function hasRoleOf(address _address, string memory _role)
        external
        view
        returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract HenkakuQuest is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant QUEST_CREATION_ROLE =
        keccak256("QUEST_CREATION_ROLE");
    bytes32 public constant HENKAKU_MEMBER_ROLE =
        keccak256("HENKAKU_MEMBER_ROLE");
    bytes32 public constant JP_LANG = keccak256("jp");
    bytes32 public constant EN_LANG = keccak256("en");
    uint256 private NULL = 0;

    event QuestUpdated(uint256 indexed id, address indexed updatedBy);

    event QuestAdded(uint256 indexed id, address indexed createdBy);

    event QuestClosed(
        uint256 indexed id,
        uint256 indexed endedAt,
        address closedBy
    );

    struct UserInputQuest {
        string lang;
        string title;
        string description;
        string category;
        string limitation;
        uint256 amount;
        uint256 endedAt;
    }

    struct Quest {
        uint256 id;
        string lang;
        string title;
        string description;
        string category;
        string limitation;
        uint256 amount;
        uint256 endedAt;
        uint256 questLangId;
        address upadatedBy;
    }

    struct QuestLang {
        uint256 jpQuestId;
        uint256 enQuestId;
    }

    address public memberShipNFTAddress;
    IHenkakuMemberShip private memberShipNFT;

    mapping(uint256 => QuestLang) private questLang;
    Quest[] private quests;
    uint256 public questLangId;

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
        _quest.upadatedBy = msg.sender;
        quests[_id] = _quest;
        emit QuestClosed(_id, _quest.endedAt, msg.sender);
    }

    function update(uint256 _questId, UserInputQuest memory _questUserInput)
        public
    {
        require(
            hasCreatQuestRole(msg.sender) || hasAdminRole(msg.sender),
            "You need to have Quest creation role or admin role to edit a quest"
        );
        require(_questId <= quests.length, "questId does not exist");
        require(
            keccak256(bytes(quests[_questId].lang)) ==
                keccak256(bytes(_questUserInput.lang)),
            "lang must be the same"
        );
        uint256 _langId = quests[_questId].questLangId;
        Quest memory _quest = Quest(
            _questId,
            quests[_questId].lang,
            _questUserInput.title,
            _questUserInput.description,
            _questUserInput.category,
            _questUserInput.limitation,
            _questUserInput.amount,
            _questUserInput.endedAt,
            _langId,
            msg.sender
        );

        quests[_questId] = _quest;
        emit QuestUpdated(_questId, msg.sender);
    }

    function save(
        UserInputQuest memory _questUserInputJP,
        UserInputQuest memory _questUserInputEN
    ) public {
        _save(_questUserInputJP, "jp", questLangId);
        questLang[questLangId].jpQuestId = quests.length - 1;

        _save(_questUserInputEN, "en", questLangId);
        questLang[questLangId].enQuestId = quests.length - 1;
        questLangId += 1;
    }

    function _save(
        UserInputQuest memory _questUserInput,
        string memory _lang,
        uint256 _questLangId
    ) internal {
        require(
            hasCreatQuestRole(msg.sender) || hasAdminRole(msg.sender),
            "You need to have Quest creation role or admin role to add a quest"
        );
        bytes32 _langBytes = keccak256(bytes(_lang));
        require(
            _langBytes == JP_LANG || _langBytes == EN_LANG,
            "languagae must be jp or en"
        );

        uint256 _questId = quests.length;
        Quest memory _quest = Quest(
            _questId,
            _lang,
            _questUserInput.title,
            _questUserInput.description,
            _questUserInput.category,
            _questUserInput.limitation,
            _questUserInput.amount,
            _questUserInput.endedAt,
            _questLangId,
            msg.sender
        );
        quests.push(_quest);
        emit QuestAdded(_questId, msg.sender);
    }

    function canReadQuest(address _address) public view returns (bool) {
        return
            hasMemberRole(_address) ||
            hasCreatQuestRole(_address) ||
            hasAdminRole(_address);
    }

    function getQuests() public view returns (Quest[] memory) {
        require(canReadQuest(msg.sender), "You dont have permission to obtain");
        return quests;
    }

    function getQuestFromLang(uint256 _questLangId) public view returns (Quest[2] memory){
        require(canReadQuest(msg.sender), "You dont have permission to obtain");
        return [
            quests[questLang[_questLangId].jpQuestId],
            quests[questLang[_questLangId].enQuestId]
        ];
    }

    function getQuest(uint256 _id) public view returns (Quest memory) {
        require(canReadQuest(msg.sender), "You dont have permission to obtain");
        return quests[_id];
    }
}
