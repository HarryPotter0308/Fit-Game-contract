//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.4;

contract GAME is ERC721, Ownable {

    uint public constant MAX_SUPPLY = 7000;
    uint public Price = 0.1 ether;
    mapping(uint => uint) private _CurrentTotalSupply;

    address private _DevAddress;
    uint private _DevBalance;
    string private _MetaURI;

    struct MintHistory {
        address minter;
        uint tokenId;
    }

    mapping(uint => address[]) private _Winners;

    mapping(uint => MintHistory[]) private _Minted;

    mapping(uint => uint) private _Rewards;

    event Minted(address indexed minter, uint price, uint tokenId);
    event Claimed(address sender, uint tokenId, string tokenUri);


    modifier _isOwner(address _oAddress) {
        require(owner() == _oAddress, "An error occurred in the verson setting");
        _;
    }

    modifier _versionLimit(uint _index) {
        require(
            _index == 1 || _index == 2 || _index == 3,
            "An error occurred in the verson setting"
        );
        _;
    }

    constructor(string memory baseURI_) ERC721("Fit In NFT", "FIT") {
        setBaseURI(baseURI_);
    }

    function setPrice(uint _price) public onlyOwner {
        Price = _price;
    }

    function _baseURI() internal view override returns (string memory) {
        return _MetaURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _MetaURI = baseURI_;
    }

    function tokenURI(uint tokenId_) public view virtual override returns (string memory) {
        require(tokenId_ > 0, "TokenID is invaliable");
        if (tokenId_ <= 1000) return string(abi.encodePacked(super.tokenURI(tokenId_), ".json"));
        else if (1000 < tokenId_ && tokenId_ < 5000) return string(abi.encodePacked(super.tokenURI(tokenId_), ".json"));
        else return string(abi.encodePacked(super.tokenURI(tokenId_), ".json"));
    }

    function setWinners(uint version, address[] memory winners_)
        public
        onlyOwner
        _versionLimit(version)
    {
        require(winners_.length > 0, "Winners must always exist");

        _Winners[version] = winners_;
    }

    function mint(uint _version)
        public
        payable
        _versionLimit(_version)
    {

        require (!(_version == 1 && _CurrentTotalSupply[1] == 1000), "V1 token can't be minted anymore.");
        require (!(_version == 2 && _CurrentTotalSupply[1] < 1000), "All v1 tokens must be minted before v2 tokens can be minted.");
        require (!(_version == 2 && _CurrentTotalSupply[2] == 5000), "V1 token can't be minted anymore");
        require (!(_version == 3 && _CurrentTotalSupply[1] == 1000 && _CurrentTotalSupply[2] == 5000), "All v1 tokens and v2 tokens must be minted before v3 tokens can be minted.");
        require (!(_version == 3 && _CurrentTotalSupply[1] == 1000 && _CurrentTotalSupply[2] == 5000 && _CurrentTotalSupply[3] == 1000), "The token can't mint anymore.");
        require(msg.value >= Price, "Price is too low");

        uint _tokenId = _CurrentTotalSupply[_version] + 1;
        
        _Minted[_version][_Minted[_version].length].tokenId = _tokenId;
        _Minted[_version][_Minted[_version].length].minter = msg.sender;
        _safeMint(msg.sender, _tokenId);

        if (_version == 1) {
            _Rewards[1] += Price * 8 / 10;
            _Rewards[2] += Price * 1 / 10;
            _DevBalance += Price * 1 / 10;
            _CurrentTotalSupply[1] ++;
        } else if (_version == 2) {
            _Rewards[2] += Price * 8 / 10;
            _Rewards[3] += Price * 1 / 10;
            _DevBalance += Price * 1 / 10;
            _CurrentTotalSupply[2] ++;
        } else {
            _Rewards[3] += Price * 8 / 10;
            _DevBalance += Price * 2 / 10;
            _CurrentTotalSupply[3] ++;
        }

        emit Minted(msg.sender, Price, _tokenId);
    }

    function distributeRewardsToWinners() public {
        uint index = 0;

        payable(_DevAddress).transfer(_DevBalance);

        while(_Minted[1].length > index) {
            payable(_Minted[1][index].minter).transfer(_Rewards[1] / _Minted[1].length);
            index ++;
        }
        index = 0;
        while(_Minted[2].length > index) {
            payable(_Minted[2][index].minter).transfer(_Rewards[2] / _Minted[2].length);
            index ++;
        }
        index = 0;
        while(_Minted[3].length > index) {
            payable(_Minted[3][index].minter).transfer(_Rewards[3] / _Minted[3].length);
            index ++;
        }
    }

    function claim() public {
        uint index = 0;
        uint tokenId_ = 0;
        while (_Minted[1][index].tokenId > 0) {
            if (msg.sender == _Minted[1][index].minter) {

                tokenId_ = ++ _CurrentTotalSupply[2];
                _safeMint(msg.sender, tokenId_);
                
                _Minted[2][_Minted[2].length].tokenId = tokenId_;
                _Minted[2][_Minted[2].length].minter = msg.sender;

                tokenId_ = _Minted[1].length - 1;
                _Minted[1][index].minter = _Minted[1][tokenId_].minter;
                _Minted[1][index].tokenId = _Minted[1][tokenId_].tokenId;
                _Minted[1].pop();
                index --;
            }
            index ++;
        }
    }
}
