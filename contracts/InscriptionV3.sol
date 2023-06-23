// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./libs/Logarithm.sol";
import "./libs/TransferHelper.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IInitialFairOffering.sol";

// This is common token interface, get balance of owner's token by ERC20/ERC721/ERC1155.
interface ICommonToken {
    function balanceOf(address owner) external returns(uint256);
}

// This contract is extended from ERC20
contract Inscription is ERC20 {
    using Logarithm for int256;

    struct FERC20 {
        uint128 cap;                            // Max amount
        uint128 limitPerMint;                   // Limitaion of each mint

        address onlyContractAddress;            // Only addresses that hold these assets can mint
        uint32  maxMintSize;                    // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint64  inscriptionId;                  // Inscription Id
        
        uint128 onlyMinQuantity;                // Only addresses that the quantity of assets hold more than this amount can mint
        uint128 crowdFundingRate;               // rate of crowdfunding

        address whitelist;                      // whitelist contract
        uint40  freezeTime;                     // The frozen time (interval) between two mints is a fixed number of seconds. You can mint, but you will need to pay an additional mint fee, and this fee will be double for each mint.
        uint16  fundingCommission;              // commission rate of fund raising, 1000 means 10%
        uint16  liquidityTokenPercent;
        bool    isIFOMode;    // receiving fee of crowdfunding

        address payable inscriptionFactory;     // Inscription factory contract address
        uint128 baseFee;                        // base fee of the second mint after frozen interval. The first mint after frozen time is free.
        address payable ifoContractAddress;
    }
    FERC20 private ferc20;

    mapping(address => uint256) private lastMintTimestamp;   // record the last mint timestamp of account
    mapping(address => uint256) private lastMintFee;           // record the last mint fee

    uint256 public totalRollups;

    constructor(
        string memory   _name,            // token name
        string memory   _tick,            // token tick, same as symbol. must be 4 characters.
        uint128         _cap,                   // Max amount
        uint128         _limitPerMint,          // Limitaion of each mint
        uint64          _inscriptionId,         // Inscription Id
        uint32          _maxMintSize,           // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint. This is only availabe for non-frozen time token.
        uint40          _freezeTime,            // The frozen time (interval) between two mints is a fixed number of seconds. You can mint, but you will need to pay an additional mint fee, and this fee will be double for each mint.
        address         _onlyContractAddress,   // Only addresses that hold these assets can mint
        uint128         _onlyMinQuantity,       // Only addresses that the quantity of assets hold more than this amount can mint
        uint128         _baseFee,               // base fee of the second mint after frozen interval. The first mint after frozen time is free.
        uint16          _fundingCommission,     // commission rate of fund raising, 100 means 1%
        uint128         _crowdFundingRate,      // rate of crowdfunding
        address         _whitelist,              // whitelist contract
        bool            _isIFOMode,              // receiving fee of crowdfunding
        uint16          _liquidityTokenPercent,
        address payable _ifoContractAddress,
        address payable _inscriptionFactory
    ) ERC20(_name, _tick) {
        require(_cap >= _limitPerMint, "Limit per mint exceed cap");
        ferc20.cap = _cap;
        ferc20.limitPerMint = _limitPerMint;
        ferc20.inscriptionId = _inscriptionId;
        ferc20.maxMintSize = _maxMintSize;
        ferc20.freezeTime = _freezeTime;
        ferc20.onlyContractAddress = _onlyContractAddress;
        ferc20.onlyMinQuantity = _onlyMinQuantity;
        ferc20.baseFee = _baseFee;
        ferc20.fundingCommission = _fundingCommission;
        ferc20.crowdFundingRate = _crowdFundingRate;
        ferc20.whitelist = _whitelist;
        ferc20.isIFOMode = _isIFOMode;
        ferc20.ifoContractAddress = _ifoContractAddress;
        ferc20.inscriptionFactory = _inscriptionFactory;
        ferc20.liquidityTokenPercent = _liquidityTokenPercent;
    }

    function mint(address _to) payable public {
        // Check if the quantity after mint will exceed the cap
        uint256 tokenForInitialLiquidity = ferc20.isIFOMode ? ferc20.limitPerMint * ferc20.liquidityTokenPercent / (10000 - ferc20.liquidityTokenPercent) : 0;
        require(totalRollups + 1 <= maxRollups(), "Touched cap");
        // Check if the assets in the msg.sender is satisfied
        require(ferc20.onlyContractAddress == address(0x0) || ICommonToken(ferc20.onlyContractAddress).balanceOf(msg.sender) >= ferc20.onlyMinQuantity, "You don't have required assets");
        require(ferc20.whitelist == address(0x0) || IWhitelist(ferc20.whitelist).getStatus(symbol(), msg.sender), "You are not in whitelist");
        require(lastMintTimestamp[msg.sender] < block.timestamp, "Timestamp fail");
        
        if(lastMintTimestamp[msg.sender] + ferc20.freezeTime > block.timestamp) {
            // The min extra tip is double of last mint fee
            lastMintFee[msg.sender] = lastMintFee[msg.sender] == 0 ? ferc20.baseFee : lastMintFee[msg.sender] * 2;
            // Check if the tip is high than the min extra fee
            require(msg.value >= ferc20.crowdFundingRate + lastMintFee[msg.sender], "Send some ETH as fee and crowdfunding");
            // Transfer the fee to the crowdfunding address
            if(ferc20.crowdFundingRate > 0) _dispatchFunding(ferc20.crowdFundingRate);
            // Transfer the tip to InscriptionFactory smart contract
            if(msg.value - ferc20.crowdFundingRate > 0) TransferHelper.safeTransferETH(ferc20.inscriptionFactory, msg.value -ferc20. crowdFundingRate);
            // Do mint
            _mint(_to, ferc20.limitPerMint);
            totalRollups++;
            // Mint for initial liquidity
            if(tokenForInitialLiquidity > 0) {
                _mint(ferc20.ifoContractAddress, tokenForInitialLiquidity);
             }
        } else {
            // Transfer the fee to the crowdfunding address
            if(ferc20.crowdFundingRate > 0) {
                require(msg.value >= ferc20.crowdFundingRate, "Send some ETH as crowdfunding");
                _dispatchFunding(msg.value);
            }
            // Out of frozen time, free mint. Reset the timestamp and mint times.
            lastMintFee[msg.sender] = 0;
            lastMintTimestamp[msg.sender] = block.timestamp;
            // Do mint
            _mint(_to, ferc20.limitPerMint);
            totalRollups++;
            // Mint for initial liquidity
            if(tokenForInitialLiquidity > 0) {
                _mint(ferc20.ifoContractAddress, tokenForInitialLiquidity);
            }
        }
    }

    // batch mint is only available for non-frozen-time tokens
    function batchMint(address _to, uint256 _num) payable public {
        uint256 tokenForInitialLiquidity = ferc20.isIFOMode ? ferc20.limitPerMint * ferc20.liquidityTokenPercent / (10000 - ferc20.liquidityTokenPercent) : 0;
        require(_num <= ferc20.maxMintSize, "exceed max mint size");
        require(totalRollups + _num <= maxRollups(), "Touch cap");
        require(ferc20.freezeTime == 0, "Batch mint only for non-frozen token");
        require(ferc20.onlyContractAddress == address(0x0) || ICommonToken(ferc20.onlyContractAddress).balanceOf(msg.sender) >= ferc20.onlyMinQuantity, "You don't have required assets");
        require(ferc20.whitelist == address(0x0) || IWhitelist(ferc20.whitelist).getStatus(symbol(), msg.sender), "You are not in whitelist");

        if(ferc20.crowdFundingRate > 0) {
            require(msg.value >= ferc20.crowdFundingRate * _num, "Crowdfunding ETH not enough");
            _dispatchFunding(msg.value);
        }
        for(uint256 i = 0; i < _num; i++) {
            _mint(_to, ferc20.limitPerMint);
            // Mint for initial liquidity
            if(tokenForInitialLiquidity > 0) {
                _mint(ferc20.ifoContractAddress, tokenForInitialLiquidity);
            }
        }
        totalRollups = totalRollups + _num;
    }

    function getMintFee(address _addr) public view returns(uint256 mintedTimes, uint256 nextMintFee) {
        if(lastMintTimestamp[_addr] + ferc20.freezeTime > block.timestamp) {
            int256 scale = 1e18;
            int256 halfScale = 5e17;
            // times = log_2(lastMintFee / baseFee) + 1 (if lastMintFee > 0)
            nextMintFee = lastMintFee[_addr] == 0 ? ferc20.baseFee : lastMintFee[_addr] * 2;
            mintedTimes = uint256((Logarithm.log2(int256(nextMintFee / ferc20.baseFee) * scale, scale, halfScale) + 1) / scale) + 1;
        }
    }

    function getFerc20Data() public view returns(FERC20 memory) {
        return ferc20;
    }

    function getLastMintTimestamp(address _addr) public view returns(uint256) {
        return lastMintTimestamp[_addr];
    }

    function getLastMintFee(address _addr) public view returns(uint256) {
        return lastMintFee[_addr];
    }

    function _dispatchFunding(uint256 _amount) private {
        require(ferc20.ifoContractAddress != address(0x0), "ifo address zero");
        require(!IInitialFairOffering(ferc20.ifoContractAddress).refundable(), "refund start");

        uint256 commission = _amount * ferc20.fundingCommission / 10000;
        TransferHelper.safeTransferETH(ferc20.ifoContractAddress, _amount - commission);
        if(commission > 0) TransferHelper.safeTransferETH(ferc20.inscriptionFactory, commission);
        IInitialFairOffering(ferc20.ifoContractAddress).setEtherLiquidity(msg.sender, _amount - commission);
    }

    function maxRollups() public view returns(uint256) {
        // Because of liquidity part after each mint, the total mintable quantity will be less than cap a little bit.
        // The total mintable will be: cap * (1 - liquidityTokenPercent) / limitPerMint
        // Because of the liquidityTokenPercent is interge, the final function will be:
        // cap * (10000 - liquidityTokenPercent) / limitPerMint / 10000
        return ferc20.cap * (10000 - ferc20.liquidityTokenPercent) / ferc20.limitPerMint / 10000;
    }
}
