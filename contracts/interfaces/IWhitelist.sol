// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelist {
    function getStatus(string memory _tick, address _addr) external view returns(bool);
}