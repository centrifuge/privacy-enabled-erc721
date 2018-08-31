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


        it("should mint a token if the Merkle proof validates", async function () {
          let documentIdentifer = "0xce5b7b97141cbf0a447e1d7bb29794f3d8ff276c5974061f4aefc90cbba35eaf"
          await this.anchorRegistry.setAnchorById(
              documentIdentifer,
              "0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744"
          );

          /**
           * This is a proof coming from the precise-proofs library via
           * https://github.com/centrifuge/precise-proofs/blob/master/examples/simple.go
           * using Keccak256 as the hashing algorithm
           * 
           */
          let validProof = [
              bufferToHex(Buffer.from("EUqfrgLuRdt+ot+3vI9qnCdybeYN3xwwe/MJVsCH2wc=", "base64")),
              bufferToHex(Buffer.from("3hsHx/etwya5rcyIe3Avw2724ThyZl9pS4tMdybn05w=", "base64")),
              bufferToHex(Buffer.from("zlt7lxQcvwpEfh17speU89j/J2xZdAYfSu/JDLujXqA=", "base64"))
          ];

          //root has is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
          let validRootHash = bufferToHex(Buffer.from("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=", "base64"));
          let salt = Buffer.from("UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=", "base64");
          
          let leafValue = Buffer.from("Foo", "utf8");
          let leafName = Buffer.from("valueA", "utf8");
          let validLeaf = bufferToHex(keccak(Buffer.concat([leafName, leafValue, salt])));

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

          /**
           * This is a proof coming from the precise-proofs library via
           * https://github.com/centrifuge/precise-proofs/blob/master/examples/simple.go
           * using Keccak256 as the hashing algorithm
           * 
           */
          let validProof = [
              bufferToHex(Buffer.from("EUqfrgLuRdt+ot+3vI9qnCdybeYN3xwwe/MJVsCH2wc=", "base64")),
              bufferToHex(Buffer.from("3hsHx/etwya5rcyIe3Avw2724ThyZl9pS4tMdybn05w=", "base64")),
              bufferToHex(Buffer.from("zlt7lxQcvwpEfh17speU89j/J2xZdAYfSu/JDLujXqA=", "base64"))
          ];

          //root has is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
          let validRootHash = bufferToHex(Buffer.from("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=", "base64"));
          let salt = Buffer.from("UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=", "base64");
          
          let invalidleafValue = Buffer.from("FooWRRROOOONG", "utf8");
          let leafName = Buffer.from("valueA", "utf8");
          let invalidLeaf = bufferToHex(keccak(Buffer.concat([leafName, invalidleafValue, salt])));

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

        /**
         * This is a proof coming from the precise-proofs library via
         * https://github.com/centrifuge/precise-proofs/blob/master/examples/simple.go
         * using Keccak256 as the hashing algorithm
         * 
         */
        let validProof = [
            bufferToHex(Buffer.from("EUqfrgLuRdt+ot+3vI9qnCdybeYN3xwwe/MJVsCH2wc=", "base64")),
            bufferToHex(Buffer.from("3hsHx/etwya5rcyIe3Avw2724ThyZl9pS4tMdybn05w=", "base64")),
            bufferToHex(Buffer.from("zlt7lxQcvwpEfh17speU89j/J2xZdAYfSu/JDLujXqA=", "base64"))
        ];

        //root has is 0x1e5e444f4c4c7278f5f31aeb407c3804e7c34f79f72b8438be665f8cee935744 in hex
        let validRootHash = bufferToHex(Buffer.from("Hl5ET0xMcnj18xrrQHw4BOfDT3n3K4Q4vmZfjO6TV0Q=", "base64"));
        let salt = Buffer.from("UXfmxueEm0hxx9zzO21HQ5Bwg8Zg64lpQfq1y2r94ys=", "base64");
        
        let leafValue = Buffer.from("Foo", "utf8");
        let leafName = Buffer.from("valueA", "utf8");
        let validLeaf = bufferToHex(keccak(Buffer.concat([leafName, leafValue, salt])));

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