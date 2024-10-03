require("@nomiclabs/hardhat-ethers");
require('dotenv').config();

module.exports = {
  solidity: "0.8.0",
  networks: {
    rinkeby: {
      url: process.env.INFURA_API,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
