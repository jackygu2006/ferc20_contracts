/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

 const HDWalletProvider = require("@truffle/hdwallet-provider");
 const Env = require("./env");
 //
 // const fs = require('fs');
 // const mnemonic = fs.readFileSync(".secret").toString().trim();
 
 module.exports = {
		 /**
			* Networks define how you connect to your ethereum client and let you set the
			* defaults web3 uses to send transactions. If you don't specify one truffle
			* will spin up a development blockchain for you on port 9545 when you
			* run `develop` or `test`. You can ask a truffle command to use a specific
			* network from the command line, e.g
			*
			* $ truffle test --network <network-name>
			*/
 
		 networks: {
			 ethMainnet: {
				 provider: () => new HDWalletProvider(
					 Env.get("PRI_KEY"),
					 Env.get("RPC_URL")
					 ),
  				network_id: Env.get("CHAIN_ID"),
				 gas: 4500000,
				 confirmations: 1,
				 timeoutBlocks: 200,
				 skipDryRun: true,
			 },
			 bscTestnet: {
					 provider: () =>new HDWalletProvider(
							 Env.get("PRI_KEY"), 
							 Env.get("RPC_URL")
					 ),
					 networkCheckTimeout: 999999,
					 network_id: Env.get("CHAIN_ID"),
					 gas: 11500000, // Ropsten has a lower block limit than mainnet
					 confirmations: 0, // # of confs to wait between deployments. (default: 0)
					 timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
					 skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
			 },
			 bscMainnet: {
					 provider: () => new HDWalletProvider(
							 Env.get("PRI_KEY"),
							 Env.get("RPC_URL")
					 ),
					 networkCheckTimeout: 999999,
					 network_id: Env.get("CHAIN_ID"),
					 gas: 5500000, // Ropsten has a lower block limit than mainnet
					 confirmations: 0, // # of confs to wait between deployments. (default: 0)
					 timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
					 skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
			 },
			 kovan: {
					 provider: () =>new HDWalletProvider(
							 Env.get("PRI_KEY"), 
							 Env.get("RPC_URL")
					 ),
					 network_id: Env.get("CHAIN_ID"),
					 gas: 11500000, // Ropsten has a lower block limit than mainnet
					 confirmations: 0, // # of confs to wait between deployments. (default: 0)
					 timeoutBlocks: 200, // # of blocks before a deployment times out  (minimum/default: 50)
					 skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
			 },
			 rinkeby: {
					 provider: () =>new HDWalletProvider(
							 Env.get("PRI_KEY"), 
							 Env.get("RPC_URL")
					 ),
					 networkCheckTimeout: 999999,
					 network_id: Env.get("CHAIN_ID"),
					 gas: 11500000, // Ropsten has a lower block limit than mainnet
					 confirmations: 1, // # of confs to wait between deployments. (default: 0)
					 timeoutBlocks: 600, // # of blocks before a deployment times out  (minimum/default: 50)
					 skipDryRun: true, // Skip dry run before migrations? (default: false for public nets )
			 },
			 mumbai: {
					 provider: () => new HDWalletProvider(
							 Env.get("PRI_KEY"), 
							 Env.get("RPC_URL")
					 ),
					 networkCheckTimeout: 999999,
					 network_id: Env.get("CHAIN_ID"),
					 confirmations: 2,
					 timeoutBlocks: 200,
					 skipDryRun: true
			 },
			 polygon: {
					 provider: () => new HDWalletProvider(
							 Env.get("PRI_KEY"),
							 Env.get("RPC_URL")
					 ),
					 networkCheckTimeout: 999999,
					 network_id: Env.get("CHAIN_ID"),
					 confirmation: 2,
					 timeoutBlocks: 200,
					 skipDryRun: true,
			 },
			 development: {
				host: "localhost",
				port: 8545,
				network_id: "999",
				gas: 11500000,
				confirmations: 1,
				skipDryRun: true,
			}
		 },
 
		 // Set default mocha options here, use special reporters etc.
		 mocha: {
				 // timeout: 100000
		 },
 
		 // Configure your compilers
		 compilers: {
				 solc: {
						 version: "0.8.8", // Fetch exact version from solc-bin (default: truffle's version)
						 settings: {          // See the solidity docs for advice about optimization and evmVersion
								 optimizer: {
										 enabled: true,
										 runs: 200
								 },
								 // evmVersion: "london"
						 }
				 },
		 },
 
		 plugins: ["truffle-contract-size", "truffle-plugin-verify"],
 
		 // Truffle DB is currently disabled by default; to enable it, change enabled:
		 // false to enabled: true. The default storage location can also be
		 // overridden by specifying the adapter settings, as shown in the commented code below.
		 //
		 // NOTE: It is not possible to migrate your contracts to truffle DB and you should
		 // make a backup of your artifacts to a safe location before enabling this feature.
		 //
		 // After you backed up your artifacts you can utilize db by running migrate as follows:
		 // $ truffle migrate --reset --compile-all
		 //
		 // db: {
		 // enabled: false,
		 // host: "127.0.0.1",
		 // adapter: {
		 //   name: "sqlite",
		 //   settings: {
		 //     directory: ".db"
		 //   }
		 // }
		 // }
 };
 