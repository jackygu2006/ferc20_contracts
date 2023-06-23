// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FERC20Dock {
    
    struct CallContract {
        string name;
        string description;
        address contractAddress;
        uint256 ratio;
        uint8[] params; // 1- uint256, 2- uint128, 3- uint64, 4- uint32, 5- uint16, 6- uint8, 7- uint, 8- bytes, 9- bytes32, 10- string memory, 11- bool, 12- address
    }

    CallContract[] private callContracts;
    address public inscriptionFactory;

    constructor(address _inscriptionFactory) {
        inscriptionFactory = _inscriptionFactory;
    }

    receive() external payable {
        
    }
    
    modifier onlyFactoryCall {
        require(msg.sender == inscriptionFactory);
        _;
    }

    function getCallContracts() public view returns(CallContract[] memory) {
        return callContracts;
    }

    function callContract(uint256 _contractId) public onlyFactoryCall {

    }
}