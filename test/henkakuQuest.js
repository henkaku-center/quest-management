const chai = require('chai')
const { expect } = require('chai')
const { ethers } = require('hardhat')
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)

describe('HenkakuQuest', function () {
  let owner, user1, user2, user3
  let nft, henkakuQuest
  const quest = {
    title: {
      jp: '日本語1',
      en: 'Foobar',
    },
    description: {
      jp: 'fobar',
      en: 'foobar',
    },
    category: 'foo',
    limitation: 'per week 40',
    amount: 100,
    endedAt: 0,
  }

  beforeEach(async () => {
    ;[owner, user1, user2, user3] = await ethers.getSigners()
    const Nft = await ethers.getContractFactory('NFT', owner)
    nft = await Nft.deploy()
    await nft.deployed()

    const HenkakuQuest = await ethers.getContractFactory('HenkakuQuest')
    henkakuQuest = await HenkakuQuest.deploy(nft.address)
    await henkakuQuest.deployed()
  })

  it('cannot add quest without certain role', async () => {
    await expect(
      henkakuQuest.connect(user1).save(quest)
    ).eventually.to.rejectedWith(Error)

    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.connect(user1).save(quest)
    const data = await henkakuQuest.getQuests()
    expect(data[0].title.jp).to.equal(quest.title.jp)
  })

  it('can update quest', async () => {
    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.connect(user1).save(quest)
    let data = await henkakuQuest.getQuests()
    expect(data[0].title.jp).to.equal(quest.title.jp)
    quest.title.jp = 'ジャパニーズ'
    await henkakuQuest.connect(user1).update(0, quest)
    data = await henkakuQuest.getQuests()
    expect(data[0].title.jp).to.equal('ジャパニーズ')
  })

  it('can close quest', async () => {
    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.save(quest)
    let data = await henkakuQuest.getQuests()

    expect(data[0].title.jp).to.equal(quest.title.jp)
    expect(data[0].endedAt).to.equal(0)

    await henkakuQuest.connect(user1).closeQuest(0)
    data = await henkakuQuest.getQuests()
    expect(data[0].endedAt).to.not.equal(0)
  })

  describe('with memberShip NFT', async () => {
    it('ADMIN_ROLE can create quest and close quest', async () => {
      await nft.mint(['ADMIN_ROLE'], user1.address)
      await henkakuQuest.connect(user1).save(quest)
      let data = await henkakuQuest.getQuests()
      expect(data[0].title.jp).to.equal(quest.title.jp)

      await henkakuQuest.connect(user1).closeQuest(0)
      data = await henkakuQuest.getQuests()
      expect(data[0].endedAt).to.not.equal(0)
    })

    it('QUEST_CREATION_ROLE can create quest', async () => {
      await nft.mint(['MEMBER_ROLE'], user1.address)
      await expect(
        henkakuQuest.connect(user1).save(quest)
      ).eventually.to.rejectedWith(Error)

      await nft.mint(['MEMBER_ROLE', 'QUEST_CREATION_ROLE'], user2.address)
      await henkakuQuest.save(quest)
      let data = await henkakuQuest.getQuests()
      expect(data[0].title.jp).to.equal(quest.title.jp)
    })

    it('QUEST_CREATION_ROLE can close a quest', async () => {
      await henkakuQuest.addQuestCreationRole(owner.address)
      await henkakuQuest.save(quest)
      let data = await henkakuQuest.getQuests()
      expect(data[0].title.jp).to.equal(quest.title.jp)
      expect(data[0].endedAt).to.equal(0)

      await henkakuQuest.save(quest)

      await nft.mint(['MEMBER_ROLE'], user1.address)
      await expect(
        henkakuQuest.connect(user1).closeQuest(0)
      ).eventually.to.rejectedWith(Error)

      await nft.mint(['MEMBER_ROLE', 'QUEST_CREATION_ROLE'], user2.address)
      await henkakuQuest.connect(user2).closeQuest(0)
      data = await henkakuQuest.getQuests()
      expect(data[0].endedAt).to.not.equal(0)
    })

    it('MEMBER_ROLE can read all quests', async () => {
      await nft.mint(['MEMBER_ROLE'], owner.address)
      await henkakuQuest.save(quest)
      const data = await henkakuQuest.getQuests()
      expect(data[0].title.jp).to.equal(quest.title.jp)

      await expect(
        henkakuQuest.connect(user1).getQuests()
      ).eventually.to.rejectedWith(Error)

      await nft.mint(['MEMBER_ROLE'], user1.address)
      const data2 = await henkakuQuest.connect(user1).getQuests()
      expect(data2[0].title.jp).to.equal(quest.title.jp)
    })
  })
})
