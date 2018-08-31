var ERC721Document = artifacts.require("ERC721Document");
var MockAnchorRegistry = artifacts.require("MockAnchorRegistry")

module.exports = function(deployer) {
  // The address of the anchor registry would have to come from the deploy scripts
  // so that the ERC-721 registry can find the anchor registry in the respective network
  deployer.deploy(MockAnchorRegistry).then(
    function() {
        return deployer.deploy(ERC721Document, "Privacy-Enabled Document", "PED", MockAnchorRegistry.address);
      }
  );
};