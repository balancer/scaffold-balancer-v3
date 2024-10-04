const ethers = require('ethers');

const address = '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14';
const checksum = ethers.utils.getAddress(address);
console.log("Checksum address:", checksum);