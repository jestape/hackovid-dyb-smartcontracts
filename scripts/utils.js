const axios = require('axios')
const { URLSearchParams } = require('url');

var verify = function(key, address, sourcecode, contractname, parameters) {

    setTimeout(async function() {
        const data = {
            apikey: key,
            module: 'contract',
            action: 'verifysourcecode',
            contractaddress: address,
            sourceCode: sourcecode,
            codeformat: 'solidity-single-file',
            contractname: contractname,
            compilerversion: 'v0.5.15+commit.6a57276f',
            optimizationUsed: 1,
            runs: 200,
            constructorArguements: parameters.substring(2),
            evmversion: 'istanbul',
            licenseType: 1
        };

        try {
            let result = await axios.post(`${getEtherscanUrl()}/api`, new URLSearchParams(data));
            console.log(`Contract ${address} verified -> ${result.toString()}`)
        } catch (error) {
            console.log(`Contract ${address} not verified -> ${error.toString()}`)
        }


    }, 30000);

};

var getInfuraUrl = function() {
    switch (parseInt(process.env.NETWORK_ID)) {
        case 1:
            return `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`;
        case 3:
            return `https://ropsten.infura.io/v3/${process.env.INFURA_PROJECT_ID}`;
        case 4:
            return `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`;
    }
};

var getEtherscanUrl = function() {
    switch (parseInt(process.env.NETWORK_ID)) {
        case 1:
            return `http://api.etherscan.io`;
        case 3:
            return `http://api-ropsten.etherscan.io`;
        case 4:
            return `http://api-rinkeby.etherscan.io`;
    }
};

module.exports = {
    verify,
    getInfuraUrl,
    getEtherscanUrl
}
