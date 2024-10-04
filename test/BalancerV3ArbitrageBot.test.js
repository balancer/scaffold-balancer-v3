const BalancerV3ArbitrageBot = artifacts.require("BalancerV3ArbitrageBot");

contract("BalancerV3ArbitrageBot", (accounts) => {
  it("should deploy successfully", async () => {
    const instance = await BalancerV3ArbitrageBot.deployed();
    assert(instance.address !== "");
  });
});
