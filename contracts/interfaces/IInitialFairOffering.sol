// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IInscriptionFactory.sol";

interface IInitialFairOffering {
    function initialize(IInscriptionFactory.Token memory _token) external;
    function setMintData(address _addr, uint256 _ethAmount, uint256 _tokenAmount, uint256 _tokenForLiquidity) external;
}
