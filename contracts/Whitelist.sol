// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IInscriptionFactory.sol";

contract Whitelist {
    IInscriptionFactory public inscriptionFactory;
    mapping(address => mapping(address => bool)) private whitelist;
    mapping(address => uint256) private count;

    constructor(IInscriptionFactory _inscriptionFactory) {
        inscriptionFactory = _inscriptionFactory;
    }

    function set(string memory _tick, address _addr, bool _status) public {
        (IInscriptionFactory.Token memory token, ) = IInscriptionFactory(inscriptionFactory).getIncriptionByTick(_tick);
        require(token.deployer == msg.sender, "Only deployer can add whitelist");
        bool currentStatus = whitelist[token.addr][_addr];
        if(_status && !currentStatus) {
            count[token.addr] = count[token.addr] + 1;
            whitelist[token.addr][_addr] = _status;
        } else if(!_status && currentStatus) {
            count[token.addr] = count[token.addr] - 1;
            whitelist[token.addr][_addr] = _status;
        }
    }

    function batchSet(string memory _tick, address[] calldata _addrs, bool _status) public {
        (IInscriptionFactory.Token memory token, ) = IInscriptionFactory(inscriptionFactory).getIncriptionByTick(_tick);
        require(token.deployer == msg.sender, "Only deployer can add whitelist");
        for(uint16 i = 0; i < _addrs.length; i++) {
            bool currentStatus = whitelist[token.addr][_addrs[i]];
            if(_status && !currentStatus) {
                count[token.addr] = count[token.addr] + 1;
                whitelist[token.addr][_addrs[i]] = _status;
            } else if(!_status && currentStatus) {
                count[token.addr] = count[token.addr] - 1;
                whitelist[token.addr][_addrs[i]] = _status;
            }
        }
    }

    function getStatus(string memory _tick, address _addr) public view returns(bool) {
        (IInscriptionFactory.Token memory token, ) = IInscriptionFactory(inscriptionFactory).getIncriptionByTick(_tick);
        return whitelist[token.addr][_addr];
    }

    function getCount(string memory _tick) public view returns(uint256) {
        (IInscriptionFactory.Token memory token, ) = IInscriptionFactory(inscriptionFactory).getIncriptionByTick(_tick);
        return count[token.addr];
    }
}