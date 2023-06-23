const InscriptionFactoryV1 = artifacts.require("InscriptionFactoryV1");
const Env = require('../env');

module.exports = function (deployer) {
    deployer.deploy(InscriptionFactoryV1);
};
