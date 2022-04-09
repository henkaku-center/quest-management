const chai = require('chai')
const { expect } = require('chai')
const { ethers } = require('hardhat')
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)

describe('HenkakuQuest', function () {
  let owner, user1, user2, user3
  let nft, henkakuQuest
  const questJP = {
    lang: 'jp',
    title: '日本語1',
    description: 'foobar',
    category: 'foo',
    limitation: 'per week 40',
    amount: 100,
    endedAt: 0,
  }

  const questEN = {
    lang: 'en',
    title: 'english',
    description: 'foobar',
    category: 'foo',
    limitation: 'per week 40',
    amount: 100,
    endedAt: 0,
  }

  beforeEach(async () => {
    [owner, user1, user2, user3] = await ethers.getSigners()
    const Nft = await ethers.getContractFactory('NFT', owner)
    nft = await Nft.deploy()
    await nft.deployed()

    const HenkakuQuest = await ethers.getContractFactory('HenkakuQuest')
    henkakuQuest = await HenkakuQuest.deploy(nft.address)
    await henkakuQuest.deployed()
  })

  it('cannot add quest without certain role', async () => {
    await expect(
      henkakuQuest.connect(user1).save(questJP, questEN)
    ).eventually.to.rejectedWith(Error)

    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.connect(user1).save(questJP, questEN)
    const data = await henkakuQuest.connect(owner).getQuests()
    expect(data[0].title).to.equal(questJP.title)
    expect(data[1].title).to.equal(questEN.title)
    expect(data[0].questLangId).to.equal(data[1].questLangId)
  })

  it('can update quest', async () => {
    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.connect(user1).save(questJP, questEN)
    let data = await henkakuQuest.getQuests()

    expect(data[0].title).to.equal(questJP.title)
    questJP.title = 'ジャパニーズ'
    await henkakuQuest.connect(user1).update(0, questJP)
    data = await henkakuQuest.getQuests()
    expect(data[0].title).to.equal('ジャパニーズ')
  })

  it('can close quest', async () => {
    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.save(questJP, questEN)
    let data = await henkakuQuest.getQuests()

    expect(data[0].title).to.equal(questJP.title)
    expect(data[0].endedAt).to.equal(0)

    await henkakuQuest.connect(user1).closeQuest(0)
    data = await henkakuQuest.getQuests()
    expect(data[0].endedAt).to.not.equal(0)
  })

  it('can get specific quest from lang', async () => {
    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.save(questJP, questEN)
    let data = await henkakuQuest.getQuestFromLang(0)
    expect(data[0].title).to.equal(questJP.title)
    expect(data[1].title).to.equal(questEN.title)
  })

  it('can get specific quest', async () => {
    await henkakuQuest.addQuestCreationRole(user1.address)
    await henkakuQuest.save(questJP, questEN)
    let data = await henkakuQuest.getQuest(1)
    expect(data.title).to.equal(questEN.title)
  })

  describe('with memberShip NFT', async () => {
    it('ADMIN_ROLE can create quest and close quest', async () => {
      await nft.mint(['ADMIN_ROLE'], user1.address)
      await henkakuQuest.connect(user1).save(questJP, questEN)
      let data = await henkakuQuest.getQuests()
      expect(data[0].title).to.equal(questJP.title)
      expect(data[1].title).to.equal(questEN.title)

      await henkakuQuest.connect(user1).closeQuest(0)
      data = await henkakuQuest.getQuests()
      expect(data[0].endedAt).to.not.equal(0)
    })

    it('QUEST_CREATION_ROLE can create quest', async () => {
      await nft.mint(['MEMBER_ROLE'], user1.address)
      await expect(
        henkakuQuest.connect(user1).save(questJP, questEN)
      ).eventually.to.rejectedWith(Error)

      await nft.mint(['MEMBER_ROLE', 'QUEST_CREATION_ROLE'], user2.address)
      await henkakuQuest.connect(user2).save(questJP, questEN)
      let data = await henkakuQuest.getQuests()
      expect(data[0].title).to.equal(questJP.title)
      expect(data[1].title).to.equal(questEN.title)
    })

    it('QUEST_CREATION_ROLE can close a quest', async () => {
      await henkakuQuest.addQuestCreationRole(owner.address)
      await henkakuQuest.save(questJP, questEN)
      let data = await henkakuQuest.getQuests()
      expect(data[0].title).to.equal(questJP.title)
      expect(data[0].endedAt).to.equal(0)

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
      await henkakuQuest.save(questJP, questEN)
      let data = await henkakuQuest.getQuests()
      expect(data[0].title).to.equal(questJP.title)
      expect(data[1].title).to.equal(questEN.title)

      await expect(
        henkakuQuest.connect(user1).getQuests()
      ).eventually.to.rejectedWith(Error)

      await nft.mint(['MEMBER_ROLE'], user1.address)
      data = await henkakuQuest.connect(user1).getQuests()
      expect(data[0].title).to.equal(questJP.title)
      expect(data[1].title).to.equal(questEN.title)
    })
  })
})
