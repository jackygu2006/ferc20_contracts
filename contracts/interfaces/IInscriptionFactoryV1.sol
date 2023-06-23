// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInscriptionFactory {
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
}