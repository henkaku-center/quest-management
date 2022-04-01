const chai = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);

describe("HenkakuQuest", function () {
  it("cannot add quest without certain role", async() => {
    const [owner, user1] = await ethers.getSigners();
    const Nft = await ethers.getContractFactory("NFT", owner)
    const nft = await Nft.deploy()
    await nft.deployed()

    const HenkakuQuest = await ethers.getContractFactory("HenkakuQuest");
    const henkakuQuest = await HenkakuQuest.deploy(nft.address);
    await henkakuQuest.deployed();

    const quest = {
      title: "hoge",
      body: "fobar",
      category: "foo",
      amount: 100,
      endedAt: 0
    }
    await expect(henkakuQuest.connect(user1).save(quest)).eventually.to.rejectedWith(Error)

    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.connect(user1).save(quest)
    const data = await henkakuQuest.getQuests()
    expect(data[0].title).to.equal(quest.title)
  })

  it("Add quests and returns them to only the henkaku member", async () => {
    const [owner, user1] = await ethers.getSigners();
    const Nft = await ethers.getContractFactory("NFT", owner)
    const nft = await Nft.deploy()
    await nft.deployed()

    const HenkakuQuest = await ethers.getContractFactory("HenkakuQuest");
    const henkakuQuest = await HenkakuQuest.deploy(nft.address);
    await henkakuQuest.deployed();

    console.log(nft.address, henkakuQuest.address)

    await nft.mint(true, owner.address)

    const quests = [
      {
        title: "hoge",
        body: "fobar",
        category: "foo",
        amount: 100,
        endedAt: 0
      },
      {
        title: "Foo",
        body: "bar",
        category: "foo",
        amount: 100,
        endedAt: 0
      },
    ]
    quests.forEach(quest => henkakuQuest.save(quest))
    const data = await henkakuQuest.getQuests()
    expect(data[0].title).to.equal(quests[0].title)

    await expect(henkakuQuest.connect(user1).getQuests()).eventually.to.rejectedWith(Error)

    await henkakuQuest.addMemberRole(user1.address)
    const data2 = await henkakuQuest.connect(user1).getQuests()
    expect(data2[0].title).to.equal(quests[0].title)
  });
});
