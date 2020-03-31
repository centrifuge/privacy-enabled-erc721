# User-Mintable Privacy-Enabled NFTs
[![Build Status](https://travis-ci.org/centrifuge/privacy-enabled-erc721.svg?branch=master)](https://travis-ci.org/centrifuge/privacy-enabled-erc721)

This repo is a sample implemtation of [user-mintable, privacy-enabled NFTs](https://medium.com/centrifuge/user-mintable-privacy-enabled-nft-via-ethereum-erc-721-662ba7e4425) showing the mint process using an on-chain anchor registry as backing for document verification.

## The General Idea

The goals of a user-mintable, privacy-enabled NFT are

* Mint an NFT that represents an off-chain asset consisting of structured data
* Allow anyone to mint the NFT who can provide a proof that they should be allowed to mint this NFT
* Proofs are validate on-chain against an "anchor registry" that holds the merkle root hash of the off-chain document
* Thus turning off-chain assets into on-chain assets, represented as an ERC-721 token

## The `mint` method

The ERC-721 registry exposes a `mint` method that allows anyone to mint an NFT, provided they can supply a proof that they should be allowed to do so. Specifically, the registry allows minting NFTs for off-chain datasets/assets utilizing merkle proofs that are supplied to the `mint` method.

The `mint` method is called with plaintext fields and their corresponding proofs. The NFT registry checks the validity of the data & merkle proof against an on-chain anchor registry. The anchor registry contains a mapping of document identifier to the merkle root of the respective document (the off-chain asset). If the merkle proof that was supplied to the mint method validates correctly, the NFT registry mints the token that represents the off-chain asset.

![NFT registry flow](docs/mint%20flow.jpg "Generalized privacy-enabled NFT minting flow")

## Utilizing [precise-proofs](https://github.com/centrifuge/precise-proofs)

The sample implementation utilizes the [precise-proofs](https://github.com/centrifuge/precise-proofs) library to generate merkle trees and proofs for structured off-chain data.

`precise-proofs` supports multiple hashing algorithms. This NFT implementation uses keccak256 as the hashing algorithm for the merkle tree/proof generation.

Please read the paper on [User-Mintable, Privacy-Enabled NFTs](https://www.centrifuge.io/assets/Privacy-Enabled%20NFTs%20Paper.pdf) for more background on the on-chain and off-chain components and the minting process.


## Development
Tinlake uses [dapp.tools](https://github.com/dapphub/dapptools) for development. Please install the `dapp` client. 

### Install Dependencies
```bash 
dapp update
```

### Run Tests
The tests for Tinlake are written in Solidity.
#### Run all tests
```bash
dapp test
```
#### Run a specific tests
A regular expression can be used to only run specific tests.
```bash
dapp test -r <REGEX> 
```
## Community
Join our public slack channel to discuss development, ask questions and contribute: [Centrifuge Slack](https://centrifuge.io/slack)
