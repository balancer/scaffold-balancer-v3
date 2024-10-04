require("dotenv").config();
// require("@nomicfoundation/hardhat-toolbox");
// require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    hardhat: {
      forking: {
        url: `https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
        blockNumber: 3250000  // Use a fixed block number for better performance
      },
    },
  },
};