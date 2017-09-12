var Presale = artifacts.require("./Presale.sol");
var ICO = artifacts.require("./CryptoTicketsICO.sol");

module.exports = function(deployer) {
  deployer.deploy(Presale, "0x1496a6f3e0c0364175633ff921e32a5d4aca5c45").then(function() {
  return deployer.deploy(ICO, Presale.address);
});;
};
