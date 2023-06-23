// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IInscriptionFactory.sol";

interface IInitialFairOffering {
    function initialize(IInscriptionFactory.Token memory _token, bytes memory _data) external;
    function refundable() external view returns(bool);
    function setEtherLiquidity(address _addr, uint256 _amount) external;
}
