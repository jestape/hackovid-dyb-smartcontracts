#!/bin/sh

echo "\n 1) Compiling the source code... \n"
docker run -v $(pwd):/sources ethereum/solc:0.5.15 -o /sources/deploy --abi --bin --overwrite --optimize --evm-version istanbul sources/contracts/DYBToken.sol > /dev/null 2>&1
docker run -v $(pwd):/sources ethereum/solc:0.5.15 -o /sources/deploy --abi --bin --overwrite --optimize --evm-version istanbul sources/contracts/DonationCenter.sol > /dev/null 2>&1

echo "\n 2) Preparing the deployment environment... \n"
docker build -t deployer . > /dev/null 2>&1

echo "\n 3) Deploying and verifying the smart contracts...\n"
docker run deployer --name deployer

echo "\n 4) Cleaning the setup...\n"

docker rmi -f node:13.11.0 ethereum/solc:0.5.15 deployer > /dev/null 2>&1
rm -rf deploy> /dev/null 2>&1

