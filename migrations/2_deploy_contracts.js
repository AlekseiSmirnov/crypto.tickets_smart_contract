var Presale = artifacts.require("./Presale.sol");
var ICO = artifacts.require("./CryptoTicketsICO.sol");
var config = require('./config.json');

module.exports = function(deployer) {
  deployer.deploy(Presale, config.ManagerForPresale).then(function() {
  return deployer.deploy(ICO, Presale.address, config.Company, config.BountyFund, config.AdvisorsFund, config.ItdFund, config.StorageFund, config.Manager, config.Controller_Address1, config.Controller_Address2, config.Controller_Address3);
});;
};
