// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInscriptionFactory {
    struct Token {
        uint128         cap;                // Hard cap of token
        uint128         limitPerMint;       // Limitation per mint

        address         onlyContractAddress;
        uint32          maxMintSize;        // max mint size, that means the max mint quantity is: maxMintSize * limitPerMint
        uint64          inscriptionId;      // Inscription id

        uint128         onlyMinQuantity;
        uint128         crowdFundingRate;
        
        address         addr;               // Contract address of inscribed token 
        uint40          freezeTime;
        uint40          timestamp;          // Inscribe timestamp
        uint16          liquidityTokenPercent;   // 10000 is 100%
        
        address         deployer;           // Deployer
        uint16          liquidityEtherPercent;
        string          tick;               // same as symbol in ERC20
        string          name;               // full name of token

        address         ifoContractAddress;      
        bool            isIFOMode;  
        bool            isWhitelist;
        string          logoUrl;            // logo url
    }

    function deploy(
        string memory _name,
        string memory _tick,
        uint256 _cap,
        uint256 _limitPerMint,
        uint256 _maxMintSize, // The max lots of each mint
        uint256 _freezeTime, // Freeze seconds between two mint, during this freezing period, the mint fee will be increased 
        address _onlyContractAddress, // Only the holder of this asset can mint, optional
        uint256 _onlyMinQuantity, // The min quantity of asset for mint, optional
        uint256 _crowdFundingRate,
        address _crowdFundingAddress
    ) external returns (address _inscriptionAddress);

    function updateStockTick(string memory _tick, bool _status) external;

    function transferOwnership(address newOwner) external;

    function getIncriptionByTick(string memory _tick) external view returns(Token memory tokens, uint256 totalSupplies);

    function getIncriptionIdByTick(string memory _tick) external view returns(uint256);

}