//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import 
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MarkleTree {
    bytes32 public root;

    function isAllowed(bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender)));
    }

    function setMarkleRoot(bytes32 _root) internal {
        root = _root;
    }
}
