// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IInscription.sol";
import "./interfaces/IInscriptionFactory.sol";
import "./libs/TransferHelper.sol";
import "./libs/BytesLib.sol";

// This contract will be created while deploying
// The liquidity can not be removed
contract InitialFairOffering {
    IInscriptionFactory public inscriptionFactory = IInscriptionFactory(0xc4fFFfe58B4557374c34BA7e5CF836463B509995); // test on mumbai, ajust while deploying

    // uint256 public initialErc20Liquidity;
    // uint256 public ethRatioToLiquidity = 5000; // How much ETH for adding liquidity, 1000 means 10%
    uint256 public mintCount;
    uint256 public totalVoteForRefund;
    uint256 public voteLine = 6666; // 6666 means 66.66%
    bool    public refundable = false;

    mapping(address => uint256) public etherLiquidity;
    mapping(address => bool) public votedForRefund;

    IInscriptionFactory.Token public token;

    constructor(IInscriptionFactory _inscriptionFactory) {
        inscriptionFactory = _inscriptionFactory;
    }

    receive() external payable {}

    // Initialize the erc20 quantity, and the same amount must be sent to here while deploying the contract
    // the input is a bytes data, formated by JSON from front-end. 
    // Json: 
    // {
    //     "dataType":[
    //         {
    //             "name":"amount",
    //             "type":"uint256",
    //             "pos":0
    //         },
    //         {
    //             "name":"ratio",
    //             "type":"uint16",
    //             "pos":32
    //         }
    //     ]
    // }
    function initialize(
        IInscriptionFactory.Token memory _token,
        bytes memory _data      // tick: test01, initialErc20Liquidity: 50000000000000000000000, ethRatioToLiquidity: 5000(50%), data: 0x000000000000000000000000000000000000000000000a968163f0a57b4000001388
    ) public {
        // Check if the deployer has sent the liquidity ferc20 tokens
        require(address(inscriptionFactory)== msg.sender, "Only inscription factory allowed");
        require(_token.inscriptionId > 0, "token data wrong");
        token = _token;
    }

    // Add liquidity
    // the input is a bytes data, formated by JSON from front-end. 
    // Json: 
    // {
    //     "dataType":[
    //         {
    //             "name":"deployer",
    //             "type":"address",
    //             "pos":0
    //         }
    //     ]
    // }
    function execute(
        bytes memory _data       // test 0x615b80388e3d3cac6aa3a904803acfe7939f0399
    ) public {
        require(!refundable, "under refunding");
        // address deployer = BytesLib.toAddress(_data, 0);
        require(token.deployer == msg.sender, "Only deployer");
        require(IInscription(token.addr).totalRollups() >= maxRollups(), "mint not finished");

        // Send ether back to deployer of ether as promise
        uint256 ethToLiquidity = address(this).balance * token.liquidityEtherPercent / 10000;
        uint256 backAmount = address(this).balance - ethToLiquidity;
        if(backAmount > 0) TransferHelper.safeTransferETH(token.deployer, backAmount);

        // Add liquidity, LP token keep in this contract, using address(this).balance and "token.cap * _token.liquidityTokenPercent / 10000"
        // TO DO
        TransferHelper.safeTransferETH(address(0x0), ethToLiquidity);

        // After mint finished, the amount of tokens in this contract is: 
        uint256 _balanceOfToken = IInscription(token.addr).balanceOf(address(this));
        uint256 _totalTokensForLiquidity = totalTokensForLiquidity() * 99999 / 100000;
        require(_balanceOfToken >= _totalTokensForLiquidity, "token not enough for liquidity");
        TransferHelper.safeTransfer(token.addr, address(0x0), _totalTokensForLiquidity); // ??
    }

    // If the mint have not finished, can vote for refunding
    // When the refund start, the minted tokens of users will not be burned. But all the tokens in this contract will be burned.
    function voteForRefund() public {
        require(etherLiquidity[msg.sender] > 0, "you have not mint");
        require(IInscription(token.addr).totalRollups() < maxRollups(), "mint has finished");
        require(!votedForRefund[msg.sender], "Voted");

        votedForRefund[msg.sender] = true;
        totalVoteForRefund++;
        if(totalVoteForRefund > mintCount * voteLine / 10000) {
            refundable = true;
            // Burn all tokens in ifo contract
            uint256 _balance = IInscription(token.addr).balanceOf(address(this));
            if(_balance > 0) TransferHelper.safeTransfer(token.addr, address(0x0), _balance);
        }
    }

    // If refunding start, user can refund the Ether by themselves.
    function refund() public {
        require(refundable, "can not refund");
        require(etherLiquidity[msg.sender] > 0, "you balance is zero");
        // Refund Ether
        TransferHelper.safeTransferETH(msg.sender, etherLiquidity[msg.sender]);
        etherLiquidity[msg.sender] = 0;
    }

    // Call from Inscription::mint only
    function setEtherLiquidity(address _addr, uint256 _amount) public {
        require(_amount > 0 && _addr != address(0x0), "setEtherLiquidity wrong params");
        require(msg.sender == token.addr, "Only call from inscription allowed");
        if(etherLiquidity[_addr] == 0) mintCount++;
        etherLiquidity[_addr] = etherLiquidity[_addr] + _amount;
    }

    function maxRollups() public view returns(uint256) {
        // Because of liquidity part after each mint, the total mintable quantity will be less than cap a little bit.
        // The total mintable will be: cap * (1 - liquidityTokenPercent) / limitPerMint
        // Because of the liquidityTokenPercent is interge, the final function will be:
        // cap * (10000 - liquidityTokenPercent) / limitPerMint / 10000
        return token.cap * (10000 - token.liquidityTokenPercent) / token.limitPerMint / 10000;
    }

    function totalTokensForLiquidity() public view returns(uint256) {
        return maxRollups() * token.limitPerMint * token.liquidityTokenPercent / (10000 - token.liquidityTokenPercent);
    }
}
