// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInscription {
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

    function mint(address _to) payable external;
    function getFerc20Data() external view returns(FERC20 memory);
    function balanceOf(address owner) external returns(uint256);
    function totalSupply() external returns(uint256);
    function totalRollups() external returns(uint256);
}