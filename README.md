# Sample Implementation of User-Mintable Privacy-Enabled NFTs

[![Build Status](https://travis-ci.org/centrifuge/privacy-enabled-erc721-base.svg?branch=master)](https://travis-ci.org/centrifuge/privacy-enabled-erc721-base)

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

## The Paper

Please read the paper on [User-Mintable, Privacy-Enabled NFTs](https://www.centrifuge.io/assets/Privacy-Enabled%20NFTs%20Paper.pdf) for more background on the on-chain and off-chain components and the minting process.

## Getting Started

This sample implementation is a [truffle](https://truffleframework.com/) project.

The easiest starting point is look at the the [ERC721Document](contracts/ERC721Document.sol#L75) implementation of the mint method. It accepts clear text values, verifies the merkle proof, and proceeds on to minting the NFT is all checks pass.

### Install/Run
Start by installing dependencies via
```
npm install
```

To run the tests in one go with ganache starting up in the same terminal (messier output and slower when running tests multiple times):
```
npm run test:withganache
```

Alternatively, run ganache in one terminal
```
npm run ganache-cli
```

And run the tests in second terminal
```
npm run test
```

## Helper commands

If you are using [reflex](https://github.com/cespare/reflex) you can run the tests whenever a file changes.

```
reflex -r "\.test\.js|\.sol" -R "node_modules" -- npm run test
```
