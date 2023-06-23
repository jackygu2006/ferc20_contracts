const Conversation = artifacts.require("Conversation");

module.exports = function (deployer) {
    deployer.deploy(Conversation);
};
