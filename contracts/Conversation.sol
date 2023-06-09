// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/String.sol";
import "./interfaces/IInscriptionFactory.sol";

// This is common token interface, get balance of owner's token by ERC20/ERC721/ERC1155.
interface ICommonToken {
    function balanceOf(address owner) external returns(uint256);
    function allowance(address owner, address spender) external returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function symbol() external returns(string memory);
}

contract Conversation is Ownable {

    struct ConversationData {
        address seller;
        uint96  lastUpdate;
        uint256 rate;
        string  name;
        string  logo;
        string  url;
    }

    mapping(address => mapping(uint8 => ConversationData)) public conversations;
    mapping(address => bool) public availabeInscriptionFactoryAddresses;

    uint8 public maxPosition = 3;
    uint256 public commission = 250;
    uint256 public frozenTime = 12 * 3600;

    string[] public prefixUrls = ["https://www.puppy.chat"];
    address public serviceAddress = 0x5F73c285D62659090f33484B9e166b0749C03044;

    constructor() {
        updateAvailabeInscriptionFactoryAddresses(0x16dabfAD608EDAC8bC77ab92a89f66E44AF6EdfA, true);
    }

    function setLink(
        address factory,
        address token,
        uint8 pos, 
        string memory name,
        string memory logo,
        string memory url, 
        uint256 amount, 
        uint256 newRate
    ) external {
        require(availabeInscriptionFactoryAddresses[factory], "factory not available");
        require(IInscriptionFactory(factory).getIncriptionIdByTick(ICommonToken(token).symbol()) > 0, "tick is not generated by factory");
        require(conversations[token][pos].lastUpdate + frozenTime < block.timestamp, "in frozen time");
        require(pos < maxPosition, "position bigger than maxPosition");
        require(token != address(0x0), "token is not ferc20");
        require(newRate <= amount, "new rate smaller than amount");
        require(amount > conversations[token][pos].rate, "must higher than current price");
        require(checkUrl(url), "url is illegal");
        require(ICommonToken(token).balanceOf(msg.sender) >= amount, "balance not enough");
        require(ICommonToken(token).allowance(msg.sender, address(this)) >= amount, "allowance not enough");

        // Send the balance of seller's offer and amount to service address
        uint256 _commission = conversations[token][pos].rate * commission / 10000;
        if(amount - conversations[token][pos].rate > 0) ICommonToken(token).transferFrom(msg.sender, serviceAddress, amount - conversations[token][pos].rate + _commission);
        // Send the seller's offer amount to seller
        if(conversations[token][pos].rate > 0) ICommonToken(token).transferFrom(msg.sender, conversations[token][pos].seller, conversations[token][pos].rate - _commission);

        // update position data
        conversations[token][pos].name = name;
        conversations[token][pos].logo = logo;
        conversations[token][pos].url = url;
        conversations[token][pos].rate = newRate;
        conversations[token][pos].seller = msg.sender;
        conversations[token][pos].lastUpdate = uint96(block.timestamp);
    }

    function getLink(address token) public view returns(ConversationData[] memory _conversations) {
        _conversations = new ConversationData[](maxPosition);
        for(uint8 i = 0; i < maxPosition; i++) {
            _conversations[i] = conversations[token][i];
        }
    }

    function checkUrl(string memory url) public view returns(bool re) {
        re = false;
        for(uint256 i = 0; i < prefixUrls.length; i++) {
            if(String.strlen(url) < String.strlen(prefixUrls[i])) continue;
            re = String.compareStrings(String.substring(url, 0, String.strlen(prefixUrls[i])), prefixUrls[i]);
        }
    }

    // =====================================
    // === Update rules by owner account ===
    // =====================================
    function updatePrefixUrl(string memory _prefixUrl) public onlyOwner {
        prefixUrls.push(_prefixUrl);
    }

    function updateServiceAddress(address addr) public onlyOwner {
        serviceAddress = addr;
    }

    function updateMaxPosition(uint8 num) public onlyOwner {
        maxPosition = num;
    }

    function updateAvailabeInscriptionFactoryAddresses(address _factoryAddress, bool _status) public onlyOwner {
        availabeInscriptionFactoryAddresses[_factoryAddress] = _status;
    }

    function updateFrozenTime(uint256 _seconds) public onlyOwner {
        frozenTime = _seconds;
    }
}