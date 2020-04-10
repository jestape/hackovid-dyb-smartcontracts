require('dotenv').config()

const { verify, getInfuraUrl } = require('./utils');

// Preparing wallet and web3 endpoint (Infura based)
const Web3 = require('web3');
const HDWalletProvider = require('truffle-hdwallet-provider');
const provider = new HDWalletProvider(process.env.PRIVATE_KEY, getInfuraUrl());
const web3 = new Web3(provider);
var BigNumber = web3.utils.BN;

// Reading smart contracts to be deployed (Single-file-based)
var fs = require('fs');

const DYBtokenABI = JSON.parse(fs.readFileSync('./abi/DYBToken.abi', 'utf8'));
const DYBtokenBIN  = fs.readFileSync('./bin/DYBToken.bin', 'utf8');
const DYBtokenSourceCode = fs.readFileSync('./contracts/DYBToken.sol', 'utf8');

const DAItokenABI = JSON.parse(fs.readFileSync('./abi/DaiToken.abi', 'utf8'));
const DAItokenBIN  = fs.readFileSync('./bin/DaiToken.bin', 'utf8');
const DAItokenSourceCode = fs.readFileSync('./contracts/DYBToken.sol', 'utf8');

const donationABI = JSON.parse(fs.readFileSync('./abi/DonationCenter.abi', 'utf8'));
const donationBIN  = fs.readFileSync('./bin/DonationCenter.bin', 'utf8');
const donationSourceCode = fs.readFileSync('./contracts/DonationCenter.sol', 'utf8');

(async () => {

	const accounts = await web3.eth.getAccounts();

	console.log(`Attempting to deploy from account: ${accounts[0]}`);

    /* ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----  */

    // Deploying DYB ERC20 Token
	const DYBdeployedToken = await new web3.eth.Contract(DYBtokenABI)
		.deploy({
			data: '0x' + DYBtokenBIN.toString(),
            arguments: [process.env.TOKEN_NAME, 
                process.env.TOKEN_SYMBOL, 
                process.env.TOKEN_DECIMALS]
        })
        .send({ from: accounts[0] });

    console.log(`DYB Token was deployed at address: ${DYBdeployedToken.options.address}`);

    // Verify DYB ERC20 Token contract
    verify(process.env.ETHERSCAN_API_KEY, 
            DYBdeployedToken.options.address, 
            DYBtokenSourceCode,
            'DYBToken', 
            web3.eth.abi.encodeParameters(
                ['string', 'string', 'uint8'],
                    [process.env.TOKEN_NAME, 
                        process.env.TOKEN_SYMBOL, 
                        process.env.TOKEN_DECIMALS]));

    /* ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----  */

    // Deploying DAI ERC20 Token
	const DAIdeployedToken = await new web3.eth.Contract(DAItokenABI)
        .deploy({
            data: '0x' + DAItokenBIN.toString(),
        })
        .send({ from: accounts[0] });

    console.log(`Dai Token was deployed at address: ${DAIdeployedToken.options.address}`);

    // Verify DAI ERC20 Token contract
    verify(process.env.ETHERSCAN_API_KEY, 
        DAIdeployedToken.options.address, 
        DAItokenSourceCode,
        'DaiToken', 
        "");

    provider.engine.stop();

    /* ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----  */

    const deployedDonation = await new web3.eth.Contract(donationABI)
		.deploy({
			data: '0x' + donationBIN.toString(),
            arguments: [DAIdeployedToken.options.address,
                DYBdeployedToken.options.address]
        })
        .send({ from: accounts[0] });

    console.log(`Donation Center was deployed at address: ${deployedDonation.options.address}`);

    // Verify DYB ERC20 Token contract
    verify(process.env.ETHERSCAN_API_KEY, 
            deployedDonation.options.address, 
            donationSourceCode,
            'DonationCenter', 
            web3.eth.abi.encodeParameters(
                ['address', 'address'],
                [DAIdeployedToken.options.address,
                    DYBdeployedToken.options.address]));

    await DYBdeployedToken.methods.addLogic(deployedDonation.options.address).send({from: accounts[0]});
    await DAIdeployedToken.methods.approve(deployedDonation.options.address, 100000).send({from: accounts[0]});
    await deployedDonation.methods.donate(10000).send({from: accounts[0]});

})();