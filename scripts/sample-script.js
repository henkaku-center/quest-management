// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const HenkakuQuest = await hre.ethers.getContractFactory("HenkakuQuest");
  const henkakuQuest = await HenkakuQuest.deploy();

  await henkakuQuest.deployed();
  const quests = [
    {
      title: "hoge",
      body: "fobar",
      amount: 100,
      endedAt: 0
    },
    {
      title: "Foo",
      body: "bar",
      amount: 100,
      endedAt: 0
    },
  ]
  quests.forEach(quest => henkakuQuest.save(quest))

  console.log("HenkakuQuest deployed to:", henkakuQuest.address);
  const data = await henkakuQuest.getQuests()
  console.log("quests", data)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
