require('dotenv').config()

const { verify, getInfuraUrl } = require('./utils');

// Preparing wallet and web3 endpoint (Infura based)
var privateKeys = [
    process.env.PRIVATE_KEY,
    "6215ea5ae8000af2adb675026bb408b563e9e33a8f829eab00a9072327995c74",
    "5041d317f382f0f516f1f6a1ba92ede88131a6fa3042b34c31041a4c1092a1a2",
    "5e983740f14369cd6675638b0fc138c0952d9228d0323803e4a23645869a7d05",
    "d8e698a69afd85b88df961f2cfc1575effb9838e349b97c1db9aa31cf9ac6cb5",
    "8274e88e0e998df9ae1cb54879ad0634acfeb896217916552168e9828a6fc58e"
];

const Web3 = require('web3');
const HDWalletProvider = require('truffle-hdwallet-provider');
const provider = new HDWalletProvider(privateKeys, getInfuraUrl(), 0 ,6);
const web3 = new Web3(provider);
const EthereumTx = require('ethereumjs-tx')
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

	accounts = await web3.eth.getAccounts();

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

    console.log("\n Account: " + accounts[0]);
    await DAIdeployedToken.methods.approve(deployedDonation.options.address, new BigNumber("1000000000000000000000000")).send({from: accounts[0]});
    console.log("Approved DAI: " + accounts[0]);
    await deployedDonation.methods.donate(10000).send({from: accounts[0]});
    console.log("Donate DAI: " + accounts[0]);

    var amounts = [0, 500, 2300, 1200, 1400, 100];

    for (i = 1; i < 6; i++) {

        console.log("\n Account: " + accounts[i]);

        await web3.eth.sendTransaction({from: accounts[0], to: accounts[i], value: web3.utils.toWei("0.05", 'ether')});
        console.log("Sent ether to: " + accounts[i]);

        await DAIdeployedToken.methods.transfer(accounts[i], amounts[i]*100).send({from:accounts[0]});
        console.log("Sent DAI to: " + accounts[i]);

        await DAIdeployedToken.methods.approve(deployedDonation.options.address, amounts[i]*100).send({from: accounts[i]});
        console.log("Approved DAI: " + accounts[i]);

        await deployedDonation.methods.donate(amounts[i]*100).send({from: accounts[i]});
        console.log("Donated DAI: " + accounts[i]);

    } 

})();