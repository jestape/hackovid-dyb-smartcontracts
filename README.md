
# DoYourBit token plaform

Generic code to automatically deploy the DoYourBit token plaform.

## Requirements

 - Docker installed
 - Infura Project ID
 - EtherScan API Key

## Setup
Clone this repository

    git clone git@github.com:jestape/hackovid-dyb-smartcontracts.git
    cd hackovid-dyb-smartcontracts

Set up .env file

    cp .env.example .env

Fill the required parameters in the .env file

    INFURA_PROJECT_ID=
    NETWORK_ID=
    PRIVATE_KEY=
    ETHERSCAN_API_KEY=
    
    TOKEN_NAME=Test 
    TOKEN_SYMBOL=
    TOKEN_DECIMALS=

Run the deploy script:

    bash scripts/deploy.sh

