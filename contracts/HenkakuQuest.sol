//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract HenkakuQuest {
    struct Quest {
        string title;
        string body;
        uint256 amount;
        uint endedAt;
    }

    Quest[] private quests;
    uint private id;

    constructor() { }

    function save(Quest memory _quest) public {
        quests.push(_quest);
    }

    function getQuests() public view returns(Quest[] memory){
        return quests;
    }
}
