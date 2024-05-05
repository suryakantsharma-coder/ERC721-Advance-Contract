//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "contracts/pricing.sol";
import "contracts/allowOperations.sol";
import "contracts/MarkleTree.sol";

// upgradable contrats.



contract MintContract is ERC721, UUPSUpgradeable, ERC721URIStorage, Price, AllowOperations, AccessControl, MarkleTree {

    // address
    address public collectionFundWallet;
    address public feeWallet;
    // address public _data;


    // ROLE 
    bytes32 public constant MINTER_ROLE = keccak256("KOMET_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATION_ROLE");

    // Mint Related Data
    uint256 internal totalSupply = 0;
    uint256 public supply = 0;
    string public base_url = "";

    // users records
    mapping(address => uint256) public wlMintedList;
    mapping(address => uint256) public publicMintedList;
    mapping(bytes => bool) public callers;

    struct mintPrams {
        uint256 amount;
        bytes functionCall;
        bytes callerId; 
        bytes32[] proof; 
    }


    constructor(string memory name, string memory symbol, address _minter, address _operator, address _collectionFundingWallet, address _feeWallet, uint256 _supply, string memory _baseuri) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE , msg.sender);
        _grantRole(MINTER_ROLE, _minter);
        _grantRole(OPERATOR_ROLE, _operator);

        collectionFundWallet = _collectionFundingWallet;
        feeWallet = _feeWallet;
        totalSupply = 1;
        supply = _supply;
        base_url = _baseuri;
    }


    function configurePriceModule(bytes calldata _data) public onlyRole(OPERATOR_ROLE) {
        (uint256 _mintPrice, uint256 _mintLimit, uint256 _feePercent, uint256 _percentDecimal ) = abi.decode(_data, (uint256, uint256, uint256, uint256)); 
        setMintPrice(_mintPrice, _mintLimit);
        setFeeCharges(_feePercent, _percentDecimal);
    }

    function mintNft(bytes calldata _data) public payable {
        (uint256 amount, string memory functionCall, bytes  memory callerId, bytes32[] memory proof) = abi.decode(_data, (uint256, string, bytes, bytes32[]));
        require(callers[callerId], "caller id is invalid");
        if (keccak256(abi.encodePacked(functionCall)) == keccak256(abi.encodePacked("publicMint"))) {
            publicMint(amount);
        } else if (keccak256(abi.encodePacked(functionCall)) == keccak256(abi.encodePacked("WhiteListMint"))) {
            WhiteListedMint(amount, proof);
        }
    }

     modifier _isUserAllowed(uint256 _amount, bytes32[] memory proof) {
        require(totalSupply + _amount <= supply, "Excced supply.");
        require(isAllowed(proof), "user is not allowed for minting");
        require(_amount * _mintPrice <= msg.value, "Insufficent funds.");
        _;
    }

    function WhiteListedMint(uint256 _amount,  bytes32[] memory proof) public payable _isUserAllowed(_amount, proof) {
        require(_isWL && wlMintedList[msg.sender] + _amount <= _mintLimit, "white list is not live or user already minted.");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 newItemId = totalSupply;
            totalSupply += 1;
            wlMintedList[msg.sender] += 1;
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, gen_uri(newItemId));
        }

        distributeFunds(payable(collectionFundWallet), payable(feeWallet));
    }


    function publicMint(uint256 _amount) public payable {
        require(_isPublic, "Public mint isn't live");
        require(totalSupply + _amount <= supply, "supply excced.");
        require(_amount * _mintPrice <= msg.value, "insufficent funds");
        require(publicMintedList[msg.sender] + _amount <= _mintLimit,"user exceed mint limit");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 newItemId = totalSupply;
            totalSupply += 1;
            publicMintedList[msg.sender] += 1;
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, gen_uri(newItemId));
        }
        
        distributeFunds(payable(collectionFundWallet), payable(feeWallet));
    }

    function setBaseUrl(string memory _uri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        base_url = _uri;
    }
  
    function setMaxSupply(uint256 _supply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supply = _supply;
    }

    function setCallersIds(bytes calldata _callerId, bool _isValid) public onlyRole(DEFAULT_ADMIN_ROLE) {
        callers[_callerId] = _isValid;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return gen_uri(tokenId);
    }

    function gen_uri(uint256 _tokenid) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(base_url, Strings.toString(_tokenid), ".json")
            );
    }


   function _authorizeUpgrade(address newImplementation) internal pure override {
    (newImplementation);
   }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage ,AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}