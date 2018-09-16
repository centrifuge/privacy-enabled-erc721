const {bufferToHex, keccak} = require("ethereumjs-util");

let ERC721Document = artifacts.require("ERC721Document");
let MockAnchorRegistry = artifacts.require("MockAnchorRegistry");
let MockERC721Document = artifacts.require("MockERC721Document");

const shouldRevert = async (promise) => {
    return await shouldReturnWithMessage(promise, "revert");
}

const shouldReturnWithMessage = async (promise, search) => {
    try {
        await promise;
        assert.fail("Expected message not received");
    } catch (error) {
        const revertFound = error.message.search(search) >= 0;
        assert(revertFound, `Expected "${search}", got ${error} instead`);
    }
}

const base64ToHex = function(_base64String){
  return bufferToHex(Buffer.from(_base64String, "base64"));
}

const produceValidLeafHash = function(_leafName, _leafValue, _salt){
  let leafName = Buffer.from(_leafName, "utf8");
  let leafValue = Buffer.from(_leafValue, "utf8");
  let salt = Buffer.from(_salt, "base64");

  return bufferToHex(keccak(Buffer.concat([leafName, leafValue, salt])));
};

const getValidProofHashes = function (){
  /**
   * This is a proof coming from the precise-proofs library via
   * https://github.com/centrifuge/precise-proofs/blob/master/examples/simple.go
   * using Keccak256 as the hashing algorithm
   * 
   */
  return [
    base64ToHex("EUqfrgLuRdt+ot+3vI9qnCdybeYN3xwwe/MJVsCH2wc="),
    base64ToHex("3hsHx/etwya5rcyIe3Avw2724ThyZl9pS4tMdybn05w="),
    base64ToHex("zlt7lxQcvwpEfh17speU89j/J2xZdAYfSu/JDLujXqA=")
  ];
}

contract("ERC721Document", function (accounts) {
    beforeEach(async function () {
        this.anchorRegistry = await MockAnchorRegistry.new();
        this.registry = await ERC721Document.new("ERC-721 Document Anchor", "TDA", this.anchorRegistry.address);
    });

    describe("ERC721Document", async function () {

        it("should be deployable as an independent registry", async function () {
            let anchorRegistry = await MockAnchorRegistry.new();
            let instance = await ERC721Document.new("ERC721 Document Anchor 2", "TDA2", anchorRegistry.address);

            assert.equal("ERC721 Document Anchor 2", await instance.name.call(), "The registry should be deployed with the specific name");
            assert.equal("TDA2", await instance.symbol.call(), "The registry should be deployed with the specific symbol");
            assert.equal(anchorRegistry.address, await instance.anchorRegistry.call(), "The registry should be deployed with the specific anchor registry");
        });


        it("should fail to deploy with an invalid anchor registry", async function () {
            await shouldRevert(ERC721Document.new("ERC721 Document Anchor", "TDA", "0x1"));
        });


        it("should be able to check if documents are registered on the anchor registry", async function () {
          let mockRegistry = await MockERC721Document.new("ERC-721 Document Anchor", "TDA", this.anchorRegistry.address);
          
          await this.anchorRegistry.setAnchorById(
            "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
          );

          assert.equal(
            false, 
            await mockRegistry.isRegisteredInRegistryWithRoot.call(
              "0x0", 
              "0x0"
            ), 
            "Registry check should fail for 0x0 data"
          );
          assert.equal(
            false, 
            await mockRegistry.isRegisteredInRegistryWithRoot.call(
              "0x9aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9", 
              "0x9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9"
            ), 
            "Registry check should fail for not-found anchor"
          );
          assert.equal(
            false, 
            await mockRegistry.isRegisteredInRegistryWithRoot.call(
              "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 
              "0x9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb9"
            ), 
            "Registry check should fail for wrong anchor merkle root"
          );

          assert.equal(
            true, 
            await mockRegistry.isRegisteredInRegistryWithRoot.call(
              "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 
              "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            ), 
            "Registry check should succeed with correct data"
          );
        });
      });


      describe("_hashLeafData", async function () {
        it("should hash the leaf data the same way JS does", async function () {
          let mockRegistry = await MockERC721Document.new("ERC-721 Document Anchor", "TDA", this.anchorRegistry.address);

          let leafName_ = "valueA";
          let leafValue_ = "Foo";
          let salt_ = "UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=";

          let validLeafHash = produceValidLeafHash(leafName_, leafValue_, salt_); 
          
          let res = await mockRegistry.hashLeafData.call(leafName_, leafValue_, base64ToHex(salt_));
          assert.equal(validLeafHash, res, "Solidity hashing should be the same as JS hashing");
        });
      });


      describe("mintMerklePlainText", async function () {
        it("should mint a token if the Merkle proof validates", async function () {
          let documentIdentifer = "0xce5b7b97141cbf0a447e1d7bb29794f3d8ff276c5974061f4aefc90cbba35eaf"
          await this.anchorRegistry.setAnchorById(
              documentIdentifer,
              "0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744"
          );

          let validProof = getValidProofHashes();

          //root hash is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
          let validRootHash = base64ToHex("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=");
          
          await this.registry.mintMerklePlainText(
              "0x1",
              1,
              documentIdentifer,
              validRootHash,
              validProof,
              "valueA", 
              "Foo", 
              base64ToHex("UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=")
          );
        });

        it("should fail to mint a token if the Merkle proof does not validate", async function () {
          let documentIdentifer = "0xce5b7b97141cbf0a447e1d7bb29794f3d8ff276c5974061f4aefc90cbba35eaf"
          await this.anchorRegistry.setAnchorById(
              documentIdentifer,
              "0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744"
          );

          let validProof = getValidProofHashes();

          //root hash is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
          let validRootHash = base64ToHex("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=");
          
          await shouldRevert( 
            this.registry.mintMerklePlainText(
              "0x1",
              1,
              documentIdentifer,
              validRootHash,
              validProof,
              "valueFAIL", 
              "Foo", 
              base64ToHex("UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=")
          ));
        });
      });


      describe("mintMerkle", async function () {
        it("should mint a token if the Merkle proof validates", async function () {
          let documentIdentifer = "0xce5b7b97141cbf0a447e1d7bb29794f3d8ff276c5974061f4aefc90cbba35eaf"
          await this.anchorRegistry.setAnchorById(
              documentIdentifer,
              "0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744"
          );

          let validProof = getValidProofHashes();

          //rooth has is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
          let validRootHash = base64ToHex("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=");
          let validLeaf = produceValidLeafHash("valueA", "Foo", "UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=");

          await this.registry.mintMerkle(
              "0x1",
              1,
              documentIdentifer,
              validRootHash,
              validProof,
              validLeaf
          ) 
        });
         
      
        it("should fail minting a token if the Merkle proof does not validate against a leaf", async function () {
          let documentIdentifer = "0xce5b7b97141cbf0a447e1d7bb29794f3d8ff276c5974061f4aefc90cbba35eaf"
          await this.anchorRegistry.setAnchorById(
              documentIdentifer,
              "0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744"
          );

          let validProof = getValidProofHashes();

          //root hash is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
          let validRootHash = bufferToHex(Buffer.from("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=", "base64"));
        
          let invalidLeaf = produceValidLeafHash("valueA", "INVALID VALUE", "UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=");

          await shouldRevert(this.registry.mintMerkle(
              "0x1",
              1,
              documentIdentifer,
              validRootHash,
              validProof,
              invalidLeaf
          ));
      });   
      
      it("should fail minting a token if the document idenfitier is not found", async function () {
        let documentIdentifer = "0xce5b7b97141cbf0a447e1d7bb29794f3d8ff276c5974061f4aefc90cbba35eaf"
        await this.anchorRegistry.setAnchorById(
            documentIdentifer,
            "0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744"
        );

        let validProof = getValidProofHashes();

        //root hash is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
        let validRootHash = bufferToHex(Buffer.from("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=", "base64"));
        let validLeaf = produceValidLeafHash("valueA", "Foo", "UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=");

        let invalidDocumentIdentifier = "0x93ab1b97141cbf0a447e1d7bb29794f3d8ff276c5974061f4aefc90cbba48afe"

        await shouldRevert(this.registry.mintMerkle(
            "0x1",
            1,
            invalidDocumentIdentifier,
            validRootHash,
            validProof,
            validLeaf
        ));
    });       
    });
});