require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.0",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gas: 2100000,
      gasPrice: 8000000000, // Customize based on network conditions
    }
  }
};

// require("@nomiclabs/hardhat-ethers");
// require("dotenv").config();

// module.exports = {
//   solidity: "0.8.0",
//   networks: {
//     goerli: {
//       url: `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
//       accounts: [`0x${process.env.PRIVATE_KEY}`]
//     }
//   }
// };

// /** @type import('hardhat/config').HardhatUserConfig */
// module.exports = {
//   solidity: "0.8.27",
// };
