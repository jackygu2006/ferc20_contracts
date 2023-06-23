/**
 * Testing Nusic Token
 */

import {execContract, execEIP1559Contract} from './web3.js';
import { createRequire } from "module"; // Bring in the ability to create the 'require' method
import dotenv from 'dotenv';
dotenv.config();
const require = createRequire(import.meta.url); // construct the require method

const rpcUrl = process.env.RPC_URL;
const chainId = process.env.CHAIN_ID * 1;
const Web3 = require('web3');
const priKey = process.env.PRI_KEY;
const web3 = new Web3(new Web3.providers.HttpProvider(rpcUrl));

const senderAddress = (web3.eth.accounts.privateKeyToAccount('0x' + priKey)).address;
const nusicContractAddress = '0x17ee8360cf84Ef49DF5B85F1d5cBd22C3a54233e'; // BSC Mainnet
// const nusicContractAddress = '0xD28Ce91781e6350Ce8bEc3A1Af5AAFC1ae18dcFe'; // BSC Testnet

const nusicContractJson = require('../build/contracts/ONusicToken.json');
const BURN_ROLE = '0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848';
const MINT_ROLE = '0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6';
const ADMIN_ROLE = '0x1effbbff9c66c5e59634f24fe842750c60d18891155c32dd155fc2d661a4c86d';

const nusicContract = new web3.eth.Contract(nusicContractJson.abi, nusicContractAddress);

nusicContract.methods.name().call().then((response) => console.log('token name', response));
nusicContract.methods.totalSupply().call().then((response) => console.log('totalSupply', response / 1e18));
nusicContract.methods.cap().call().then((response) => console.log('cap', response));
// nusicContract.methods.balanceOf('0x615b80388E3D3CaC6AA3a904803acfE7939f0399').call().then((response) => console.log('balanceOf', response / 1e18));
nusicContract.methods.owner().call().then((owner) => console.log('owner', owner));
nusicContract.methods.MINTER_ROLE().call().then((response) => console.log('MINTER_ROLE', response));
nusicContract.methods.BURNER_ROLE().call().then((response) => console.log('BURNER_ROLE', response));
nusicContract.methods.DEFAULT_ADMIN_ROLE().call().then((response) => console.log('DEFAULT_ADMIN_ROLE', response));

nusicContract.methods.getRoleAdmin(ADMIN_ROLE).call().then((response) => console.log('getRoleAdmin', response));
nusicContract.methods.getRoleMemberCount(MINT_ROLE).call().then((response) => {
	console.log('mint roles', response)
	for(let i = 0; i < response; i++) {
		nusicContract.methods.getRoleMember(MINT_ROLE, i).call().then((response) => console.log("Mint Role #", i, response))
	}
});
nusicContract.methods.getRoleMemberCount(BURN_ROLE).call().then((response) => {
	console.log('burn roles', response)
	for(let i = 0; i < response; i++) {
		nusicContract.methods.getRoleMember(BURN_ROLE, i).call().then((response) => console.log("Burn Role #", i, response))
	}
});



/**
 * ==== Following testing methods is Send Tx ====
 */
let sendEncodeABI;
const callContract = (encodeABI, contractAddress, value) => execContract(web3, chainId, priKey, encodeABI, value === null ? 0:value, contractAddress, null, null, null, null);	
const callEIP1559Contract = (encodeABI, contractAddress, value) => execEIP1559Contract(web3, chainId, priKey, encodeABI, value === null ? 0:value, contractAddress, null, null, null, null);	

// sendEncodeABI = nusicContract.methods.mint(
// 	'0xC4BFA07776D423711ead76CDfceDbE258e32474A', 
// 	'100000000000000000000').encodeABI(); 

// sendEncodeABI = nusicContract.methods.burn('0x615b80388E3D3CaC6AA3a904803acfE7939f0399', '10000000000000000000').encodeABI();

// sendEncodeABI = nusicContract.methods.transfer('0x3444E23231619b361c8350F4C83F82BCfAB36F65', '72000000000000000000').encodeABI();
// sendEncodeABI = nusicContract.methods.transferOwnership('0xC4BFA07776D423711ead76CDfceDbE258e32474A').encodeABI();

// Grand TokenVesting contract as MINT_ROLE
// const TokenVestingAddress = '0x76624c221287b1552a379e597166CA8fAA06dF9D'; // kovan
const grantAddress = '0xc5EeB77dCe7FeC2E2C69F9BfEB799a2da85958f7';
// const TokenVestingAddress = '0x41Aacd3cF89235EB40757964A702d8A199dF81b0'; // bsc Mainnet
// sendEncodeABI = nusicContract.methods.grantRole(
// 	BURN_ROLE, 
// 	grantAddress
// ).encodeABI();

// sendEncodeABI = nusicContract.methods.setTransferAllowed(true).encodeABI();

// callContract(sendEncodeABI, nusicContractAddress);
