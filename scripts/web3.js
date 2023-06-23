import { createRequire } from "module"; // Bring in the ability to create the 'require' method
import {default as common} from '@ethereumjs/common';
const Common = common.default;
const require = createRequire(import.meta.url); // construct the require method
const Tx = require('ethereumjs-tx');
const { FeeMarketEIP1559Transaction } = require( '@ethereumjs/tx' );

export const execEIP1559Contract = (web3, chainId, priKey, sendEncodeABI, value, contractAddress, onTransactionHashFun, onConfirmedFunc, onReceiptFunc, onErrorFunc) => {
	const senderAddress = (web3.eth.accounts.privateKeyToAccount('0x' + priKey)).address;
	console.log(senderAddress);

	try {
		web3.eth.estimateGas({
			to: contractAddress,
			data: sendEncodeABI,
			value: web3.utils.toHex(value),
			from: senderAddress
		}).then((estimateGas) => {
			console.log("estimateGas: " + estimateGas);
			// web3.eth.getMaxPriorityFeePerGas().then((price) => {
			// 	console.log('price' + price);
				web3.eth.getTransactionCount(senderAddress).then((transactionNonce) => {
					console.log('nonce', transactionNonce);
					sendEIP1559Transaction(web3, {
						chainId: web3.utils.toHex(chainId),
						nonce: web3.utils.toHex(transactionNonce),
						gasLimit: web3.utils.toHex(estimateGas),
						maxFeePerGas: web3.utils.toHex(3000000000), // 3GWei
						maxPriorityFeePerGas: web3.utils.toHex(2000000000), // price,
						to: contractAddress,
						value: web3.utils.toHex(value),
						from: senderAddress,
						data: sendEncodeABI,
						accessList: [],
						type: "0x02"
					}, priKey)
					.on('transactionHash', txHash => {
						console.log('transactionHash:', txHash)
						if(onTransactionHashFun !== null) onTransactionHashFun(txHash);
					})
					.on('receipt', receipt => {
						console.log('receipt:', receipt)
						if(onReceiptFunc !== null) onReceiptFunc(receipt);
					})
					.on('confirmation', (confirmationNumber, receipt) => {
						if(confirmationNumber >=1 && confirmationNumber < 2) {
							console.log('confirmations:', confirmationNumber);
							if(onConfirmedFunc !== null) onConfirmedFunc(confirmationNumber, receipt);
						}
					})
					.on('error:', error => {
						console.error(error)
						if(onErrorFunc !== null) onErrorFunc(error);
					})
				})
			})
		// });
	} catch (err) {
		console.log(err);
		if(onErrorFunc !== null) onErrorFunc(error);
	}
}

export const execContract = (
	web3, 
	chainId, 
	priKey, 
	sendEncodeABI, 
	value, 
	nonce, 
	contractAddress, 
	onTransactionHashFun, 
	onConfirmedFunc, 
	onReceiptFunc, 
	onErrorFunc,
	gas,
	gasPrice,
) => {
	const senderAddress = (web3.eth.accounts.privateKeyToAccount('0x' + priKey)).address;
	try {
		web3.eth.getTransactionCount(senderAddress).then((transactionNonce) => {
			// console.log("transaction nonce: " + (nonce === null ? transactionNonce : nonce));
			const txData = {
				chainId,
				nonce: nonce === null ?  web3.utils.toHex(transactionNonce) : web3.utils.toHex(nonce),
				gasLimit: web3.utils.toHex(gas === 0 || gas === undefined ? 300000 : gas), // If out of gas, change it according to estimateGas
				// ###### Change default gas price
				gasPrice: web3.utils.toHex(gasPrice === 0 || gasPrice === undefined ? 5000000000 : gasPrice), // Gas price for bsc mainnet is 5000000000(5GWei), and 10000000000 for testnet
				value: web3.utils.toHex(value),
				to: contractAddress,
				from: senderAddress,
				data: sendEncodeABI
			};
	
			sendRawTransaction(web3, txData, priKey)
				.on('transactionHash', txHash => {
					console.log('transactionHash:', txHash)
					if(onTransactionHashFun !== null) onTransactionHashFun(txHash, transactionNonce);
				})
				.on('receipt', receipt => {
					console.log('receipt:', receipt)
					if(onReceiptFunc !== null) onReceiptFunc(receipt);
				})
				.on('confirmation', (confirmationNumber, receipt) => {
					if(confirmationNumber >=1 && confirmationNumber < 2) {
						console.log('confirmations:', confirmationNumber);
						if(onConfirmedFunc !== null) onConfirmedFunc(confirmationNumber, receipt);
						// exit(0);
					}
				})
				.on('error:', error => {
					console.error(error)
					if(onErrorFunc !== null) onErrorFunc(error);
				})
		});
	} catch (err) {
		onErrorFunc(err);
	}
}

const sendRawTransaction = (web3, txData, priKey) => {
	// const transaction = new Tx(txData, {common: BSC_TEST});
	const transaction = new Tx(txData, {chain: 'kovan'});
	const privateKey = new Buffer.from(priKey, "hex");
	transaction.sign(privateKey);
	const serializedTx = transaction.serialize().toString('hex');
	return web3.eth.sendSignedTransaction('0x' + serializedTx);
}

const sendEIP1559Transaction = (web3, txData, priKey) => {
	const chain = new Common( { chain : 'rinkeby', hardfork : 'london' } );
	const privateKey = new Buffer.from(priKey, "hex");
	const transaction = FeeMarketEIP1559Transaction.fromTxData( txData , { chain } );
	const signedTransaction = transaction.sign(privateKey);
	const serializedTransaction = '0x' + signedTransaction.serialize().toString('hex');
	return web3.eth.sendSignedTransaction( serializedTransaction );
}