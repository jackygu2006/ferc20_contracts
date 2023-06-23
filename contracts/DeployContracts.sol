// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./InscriptionV3.sol";
import "./InitialFairOffering.sol";

library DeployInscriptionContract {
    function deploy(
        uint64 _inscriptionId,
        string memory _name,
        string memory _tick,
        uint128 _cap,
        uint128 _limitPerMint,
        uint32  _maxMintSize, // The max lots of each mint
        uint40 _freezeTime, // Freeze seconds between two mint, during this freezing period, the mint fee will be increased 
        address _onlyContractAddress, // Only the holder of this asset can mint, optional
        uint128 _onlyMinQuantity, // The min quantity of asset for mint, optional
        uint128 _baseFee,
        uint16 _fundingCommission,
        uint128 _crowdFundingRate,
        address _whitelistContract,
        bool    _isIFOMode,
        uint16  _liquidityTokenPercent,     // 5000 means 50%
        address  _ifoContractAddress,
        address _factoryAddress
    ) public returns(address inscriptionAddress) {
        bytes memory bytecode = type(Inscription).creationCode;
		bytecode = abi.encodePacked(bytecode, abi.encode(
            _name, 
            _tick, 
            _cap, 
            _limitPerMint, 
            _inscriptionId, 
            _maxMintSize,
            _freezeTime,
            _onlyContractAddress,
            _onlyMinQuantity,
            _baseFee,
            _fundingCommission,
            _crowdFundingRate,
            _whitelistContract,
            _isIFOMode,
            _liquidityTokenPercent,
            _ifoContractAddress,
            _factoryAddress
        ));

		bytes32 salt = keccak256(abi.encodePacked(_inscriptionId));
        // address _inscriptionAddress = address(0x0);
		assembly ("memory-safe") {
			inscriptionAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
			if iszero(extcodesize(inscriptionAddress)) {
				revert(0, 0)
			}
		}
    }
}

library DeployIFOContract {
    function deploy(address _factoryContractAddress) public returns(address ifoAddress) {
        bytes memory bytecode = type(InitialFairOffering).creationCode;
		bytecode = abi.encodePacked(bytecode, abi.encode(_factoryContractAddress));
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));

		assembly ("memory-safe") {
			ifoAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
			if iszero(extcodesize(ifoAddress)) {
				revert(0, 0)
			}
		}
    }
}