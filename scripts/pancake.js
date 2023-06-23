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
 
 const pancakeAddress = '0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3'; // BSC Testnet 
 const pancakeJson = require('../build/contracts/Pancake.json');
 const pancake = new web3.eth.Contract(pancakeJson, pancakeAddress);
 
 const NUSIC = process.env.TOKEN_ADDRESS;
 const USDT = process.env.PAYMENT_TOKEN_ADDRESS;

 pancake.methods.getAmountsOut(Web3.utils.toWei('100'), [NUSIC, USDT]).call().then((res) => console.log('getAmountsOut', res));

 /**
	* ==== Following testing methods is Send Tx ====
	*/
 let sendEncodeABI;
 const callContract = (encodeABI, contractAddress, value) => execContract(web3, chainId, priKey, encodeABI, value === null ? 0:value, contractAddress, null, null, null, null);	
 const callEIP1559Contract = (encodeABI, contractAddress, value) => execEIP1559Contract(web3, chainId, priKey, encodeABI, value === null ? 0:value, contractAddress, null, null, null, null);	
 
// callContract(sendEncodeABI, vaultAddress);
