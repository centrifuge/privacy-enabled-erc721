pragma solidity >=0.4.24;

contract IAssetManager {
  function isAssetValid(bytes32 asset) external view returns (bool);
}

contract AssetVerifier {
  IAssetManager assetManager;

  function _verify_asset(address to, bytes[] memory properties, bytes[] memory values, bytes32[] memory salts) internal view returns (bool) {
    require(to != address(0), "not a valid address");

    // construct assetHash from the props, values, salts
    // append to address
    bytes memory hash = abi.encodePacked(to);

    // append hashes
    for (uint i=0; i< properties.length; i++) {
      hash = abi.encodePacked(hash, keccak256(abi.encodePacked(properties[i], values[i], salts[i])));
    }

    return assetManager.isAssetValid(keccak256(hash));
  }
}
