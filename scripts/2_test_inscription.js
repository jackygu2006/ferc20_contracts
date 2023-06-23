/**
 * Testing Nusic Token
 */

import {execContract, execEIP1559Contract} from './web3.js';
import { createRequire } from "module"; // Bring in the ability to create the 'require' method
import sleep from 'sleep-promise';
import dotenv from 'dotenv';
dotenv.config();
const require = createRequire(import.meta.url); // construct the require method

const rpcUrl = process.env.RPC_URL;
const chainId = process.env.CHAIN_ID * 1;
const Web3 = require('web3');
const priKey = process.env.PRI_KEY;
const web3 = new Web3(new Web3.providers.HttpProvider(rpcUrl));

// const redis = require('redis');
// const client = redis.createClient();
// client.on('error', (err) => console.log('Redis Client Error', err));
// client.connect();

const senderAddress = (web3.eth.accounts.privateKeyToAccount('0x' + priKey)).address;
console.log('Sender Address: ' + senderAddress);

const inscriptionAddress = process.env.FERC20_TOKEN;

const inscriptionJson = require('../build/contracts/Inscription.json');

const inscriptionContract = new web3.eth.Contract(inscriptionJson.abi, inscriptionAddress);

inscriptionContract.methods.name().call().then((response) => console.log('token name', response));
inscriptionContract.methods.totalSupply().call().then((response) => console.log('totalSupply', response / 1e18));
inscriptionContract.methods.cap().call().then((response) => console.log('cap', response / 1e18));
inscriptionContract.methods.freezeTime().call().then((response) => console.log('freezeTime', response));
inscriptionContract.methods.lastMintTimestamp(senderAddress).call().then((response) => console.log('lastMintTimestamp', response));
inscriptionContract.methods.crowdFundingRate().call().then((response) => console.log('crowdFundingRate', response));

web3.eth.getBlock().then((response) => console.log("block timestamp", response.timestamp));


/**
 * ==== Following testing methods is Send Tx ====
 */
let sendEncodeABI;
const callContract = (encodeABI, contractAddress, value) => execContract(web3, chainId, priKey, encodeABI, value === null ? 0:value, null, contractAddress, null, null, null, null);	
const callContractWithNonce = (encodeABI, contractAddress, value, nonce) => execContract(web3, chainId, priKey, encodeABI, value === null ? 0 : value, nonce, contractAddress, null, null, null, null);	
const callEIP1559Contract = (encodeABI, contractAddress, value) => execEIP1559Contract(web3, chainId, priKey, encodeABI, value === null ? 0:value, contractAddress, null, null, null, null);	
const callContractWithFunction = (encodeABI, contractAddress, onHashFunc, onConfirmedFunc, onErrorFunc) => execContract(web3, chainId, priKey, encodeABI, 0, null, contractAddress, onHashFunc, onConfirmedFunc, null, onErrorFunc);	
const callContractWithPriKeyFunction = (privateKey, encodeABI, contractAddress, onHashFunc, onConfirmedFunc, onErrorFunc) => execContract(web3, chainId, privateKey, encodeABI, 0, null, contractAddress, onHashFunc, onConfirmedFunc, null, onErrorFunc);

sendEncodeABI = inscriptionContract.methods.mint('0x615b80388E3D3CaC6AA3a904803acfE7939f0399').encodeABI(); 
console.log("sendEncodeABI", sendEncodeABI);

// 1- 测试手动nonce递增，会不会突破？不会，第二次增加nonce之后，会出现 timestamp fail 错误
// callContractWithFunction(sendEncodeABI, inscriptionAddress, (tx, nonce) => {
// 		// onHashFunction
// 		const nextNonce = parseInt(nonce) + 1;
// 		console.log("current nonce: ", nonce);
// 		console.log("next nonce: ", nextNonce);
// 		callContractWithNonce(sendEncodeABI, inscriptionAddress, 250000000000000, nextNonce);
// }, () => {}, () => {});

// 2- 测试延迟一段时间后发送第二笔交易（支付足额小费）
// callContractWithFunction(sendEncodeABI, inscriptionAddress, (tx, nonce) => {
// 	// onHashFunction
// 	const nextNonce = parseInt(nonce) + 1;
// 	console.log("current nonce: ", nonce);
// 	console.log("next nonce: ", nextNonce);
// 	console.log("wait...");
// 	// 延迟5秒
// 	sleep(5000).then(() => {
// 		console.log("Do the 2nd tx");
// 		callContractWithNonce(sendEncodeABI, inscriptionAddress, 250000000000000, nextNonce);
// 	});
// }, () => {}, () => {});

// 3- 测试延迟一段时间后发送第二笔交易（没有支付足额小费），失败
// callContractWithFunction(sendEncodeABI, inscriptionAddress, (tx, nonce) => {
// 	// onHashFunction
// 	const nextNonce = parseInt(nonce) + 1;
// 	console.log("current nonce: ", nonce);
// 	console.log("next nonce: ", nextNonce);
// 	console.log("wait...");
// 	// 延迟5秒
// 	sleep(5000).then(() => {
// 		console.log("Do the 2nd tx");
// 		callContractWithNonce(sendEncodeABI, inscriptionAddress, 0, nextNonce);
// 	});
// }, () => {}, () => {});
