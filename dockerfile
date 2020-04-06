FROM node:13.11.0

COPY package.json deployment/
RUN cd deployment && npm install

COPY scripts/deploy.js deployment/
COPY scripts/utils.js deployment/
  
COPY deploy/DYBToken.abi deployment/abi/
COPY deploy/DYBToken.bin deployment/bin/
COPY contracts/DYBToken.sol deployment/contracts/

COPY deploy/DaiToken.abi deployment/abi/
COPY deploy/DaiToken.bin deployment/bin/

COPY deploy/DonationCenter.abi deployment/abi/
COPY deploy/DonationCenter.bin deployment/bin/
COPY contracts/DonationCenter.sol deployment/contracts/

COPY .env /deployment/

WORKDIR deployment/

ENTRYPOINT node deploy.js