pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "./nft.sol";

contract AssetNFT is NFT {

    // compact property for "Originator"
    bytes constant internal ORIGINATOR = hex"010000000000001ce24e7917d4fcaf79095539ac23af9f6d5c80ea8b0d95c9cd860152bff8fdab1700000005";
    // compact property for "AssetValue"
    bytes constant internal ASSET_VALUE = hex"010000000000001ccd35852d8705a28d4f83ba46f02ebdf46daf03638b40da74b9371d715976e6dd00000005";
    // compact property for "AssetIdentifier"
    bytes constant internal ASSET_IDENTIFIER = hex"010000000000001cbbaa573c53fa357a3b53624eb6deab5f4c758f299cffc2b0b6162400e3ec13ee00000005";
    // compact property for "MaturityDate"
    bytes constant internal MATURITY_DATE = hex"010000000000001ce5588a8a267ed4c32962568afe216d4ba70ae60576a611e3ca557b84f1724e2900000005";

    struct TokenData {
        address originator;
        uint asset_value;
        bytes32 asset_id;
        uint64 maturity_date;
    }
    mapping (uint => TokenData) public data;

    constructor (address assetManager_, address identityFactory_) NFT("Asset NFT", "ANFT", assetManager_, identityFactory_) public {
    }

    function mint(address to, uint tkn, bytes32 dataRoot, bytes[] memory properties, bytes[] memory values, bytes32[] memory salts) public {
        // verify asset
        _verifyAsset(to, properties, values, salts);

        // verify originator, we expect first property and value to be originator proof.
        _verifyOriginator(properties[0], values[0]);

        // verify if the originator is centrifuge ID and the signature is signed by originator.
        // we expect second value to be originator signature proof.
        _signed_document(msg.sender, dataRoot, values[1]);

        // uniqueness check for NFT
        // we expect 3rd property and value to be uniqueness proof
        _checkTokenData(tkn, properties[2], values[2]);

        // proof for asset_value
        // we expect 4th property and value to be asset_value proof.
        _verifyAssetValue(properties[3]);

        // proof for asset_id
        // we expect 5th property and value to be asset_id proof.
        _verifyAssetIdentifier(properties[4], values[4]);

        // proof for maturity_date
        // we expect 6th property and value to be maturity_date proof.
        _verifyMaturityDate(properties[5]);
        data[tkn] = TokenData(
            msg.sender,
            abi.decode(values[3], (uint)),
            abi.decode(values[4], (bytes32)),
            uint64(_bytesToUint(values[5]))
        );
        _mint(to, tkn);
    }

    function _bytesToUint(bytes memory b) internal pure returns (uint){
        uint256 number;
        for (uint i = 0; i < b.length; i++){
            number = number + uint8(b[i]) * (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    function _verifyOriginator(bytes memory prop, bytes memory value) internal view {
        // ensure prop matches the originator value
        require(_equalBytes(prop, ORIGINATOR), "anft/originator-property-mismatch");
        address originator = bytesToAddress(value);
        // ensure sender is originator
        require(originator == msg.sender, "anft/sender-not-originator");
    }

    function _verifyAssetValue(bytes memory prop) internal pure {
        // ensure prop matches the asset_value value
        require(_equalBytes(prop, ASSET_VALUE), "anft/asset-value-property-mismatch");
    }

    function _verifyAssetIdentifier(bytes memory prop, bytes memory value) internal pure {
        // ensure prop matches the asset_id value
        require(_equalBytes(prop, ASSET_IDENTIFIER), "anft/asset-id-property-mismatch");
        require(value.length == 32, "aonft/asset-id length not 32 bytes");
    }

    function _verifyMaturityDate(bytes memory prop) internal pure {
        // ensure prop matches the maturity_date value
        require(_equalBytes(prop, MATURITY_DATE), "anft/maturity-date-property-mismatch");
    }
}

