// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libs/String.sol";
import "./interfaces/IInscription.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IInscriptionFactory.sol";

contract Test is Ownable {
    IInscriptionFactory public factoryContract = IInscriptionFactory(address(0x0));
    IInscription public fercContrace = IInscription(address(0x0));

    string[] public stockTicks = [
        "ferc",
        "fdao",
        "cash",
        "fair",
        "web3",
        unicode"卧槽牛逼",
        "ordi",
        "feth",
        "shib",
        "mama",
        "doge",
        "punk",
        "fomo",
        "rich",
        "pepe",
        "elon",
        "must",
        "bayc",
        "sinu",
        "zuki",
        "migo",
        "fbtc",
        "erc2",
        "fare",
        "okbb",
        "lady",
        "meme",
        "oxbt",
        "dego",
        "frog",
        "moon",
        "weth",
        "jeet",
        "fuck",
        "piza",
        "oerc",
        "baby",
        "mint",
        "8==d",
        "pipi",
        "fxen",
        "king",
        "anti",
        "papa",
        "fish",
        "jack",
        "defi",
        "l1l2",
        "niub",
        "weid",
        "perc",
        "baba",
        "$eth",
        "fbnb",
        "shan",
        "musk",
        "drac",
        "kids",
        "tate",
        "fevm",
        "0x0x",
        "topg",
        "aaaa",
        "8686",
        unicode"梭进去操",
        "hold",
        "fben",
        "hash",
        "dddd",
        "fnft",
        "fdog",
        "abcd",
        "free",
        "$cpt",
        "gwei",
        "love",
        "cola",
        "0000",
        "flat",
        "core",
        "heyi",
        "ccup",
        "fsbf",
        "fers",
        "6666",
        "xxlb",
        "nfts",
        "nbat",
        "nfty",
        "jcjy",
        "nerc",
        "aiai",
        "czhy",
        "ftrx",
        "code",
        "mars",
        "pemn",
        "carl",
        "fire",
        "hodl",
        "flur",
        "exen",
        "bcie",
        "fool",
        unicode"中国牛逼",
        "jump",
        "shit",
        "benf",
        "sats",
        "intm",
        "dayu",
        "whee",
        "pump",
        "sexy",
        "dede",
        "ebtc",
        "bank",
        "flok",
        "meta",
        "flap",
        "$cta",
        "maxi",
        "coin",
        "ethm",
        "body",
        "frfd",
        "erc1",
        "ququ",
        "nine",
        "luck",
        "jomo",
        "giga",
        "weeb",
        "0001",
        "fev2"
];

    function batchUpdateStockTick(bool status) public onlyOwner {
        for(uint256 i = 0; i < stockTicks.length; i++) {
            factoryContract.updateStockTick(stockTicks[i], status);
        }
    }

    function setFactoryContract(address _addr) external onlyOwner {
        factoryContract = IInscriptionFactory(_addr);
    }

    function transferOwnershipOfFactory(address _addr) external onlyOwner {
        factoryContract.transferOwnership(_addr);
    }

    function updateFerc20Contrace(address _addr) external onlyOwner {
        fercContrace = IInscription(_addr);
    }

    function batchMint(address _to, uint256 _num) external onlyOwner {
        // This function should be fail on V2
        for(uint256 i = 0; i < _num; i++) fercContrace.mint(_to);
    }
}
