var Token = artifacts.require("Token");
var Crowdsale = artifacts.require("CrowdsaleToken");
var BigNumber = web3.utils.BN;
require('dotenv').config()

module.exports = function(deployer) {

    deployer.deploy(Token, 
        new BigNumber(10).pow(new BigNumber(process.env.TOKEN_DECIMALS)).mul(new BigNumber(process.env.TOKEN_CAP)),
            web3.utils.toChecksumAddress(process.env.TOKEN_PREFUND_ADDRESS), 
            new BigNumber(10).pow(new BigNumber(process.env.TOKEN_DECIMALS)).mul(new BigNumber(process.env.TOKEN_PREFUND_AMOUNT)),
            process.env.TOKEN_NAME, 
            process.env.TOKEN_SYMBOL,
            process.env.TOKEN_DECIMALS).then(() => {      
                return deployer.deploy(Crowdsale, 
                    new BigNumber(10).pow(new BigNumber(process.env.TOKEN_DECIMALS)).div(new BigNumber(web3.utils.toWei(process.env.CROWDSALE_PRICE, 'ether'))),
                        process.env.CROWDSALE_ADMIN_ADDRESS, 
                        Token.address,
                        process.env.CROWDSALE_OPENNING_TIME, 
                        process.env.CROWDSALE_CLOSING_TIME).then( () => {                                
                            Token.deployed().then(instance => { return instance.addMinter(Crowdsale.address)})
                        });
            })
    };