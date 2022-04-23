//SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity >=0.6.0 <0.8.0;

contract GAME is ERC721, Ownable {
    mapping(address => uint256) private _Balances;
    address private _Dev;
    uint256 private _DevBalance;
    uint256 public Price;

    struct MintHistory {
        address minter;
        uint256 tokenId;
    }

    mapping(uint256 => address[]) private _Winners;

    mapping(uint256 => MintHistory[]) private _Minted;

    mapping(uint256 => uint256) private _Rewards;

    modifier _isOwner(address _oAddress) {
        require(owner() == _oAddress, "An error occurred in the verson setting");
        _;
    }

    modifier _versionLimit(uint256 _index) {
        require(
            _index == 1 || _index == 2 || _index == 3,
            "An error occurred in the verson setting"
        );
        _;
    }

    constructor(uint256 _price) ERC721("Fit In NFT", "FIT") {
        Price = _price;
    }

    function setPrice(uint256 _price) public onlyOwner {
        Price = _price;
    }

    function setWinners(uint256 version, uint256[] memory winners)
        public
        onlyOwner
        _versionLimit(version)
    {
        require(winners[0], "Winners must always exist");

        uint256 index = 0;
        _Winners[version] = [];
        while (winners[index]) {
            _Winners[version][index] = winners[index];
        }
    }

    function mint(string memory _tokenURI, uint256 _version)
        public
        payable
        _versionLimit(_version)
    {
        require(msg.value >= Price, "Price is too low");
        uint256 _tokenId = totalSupply() + 1;
        
        _Minted[_version][_Minted[_version].length].tokenID = _tokenId;
        _Minted[_version][_Minted[_version].length].minter = msg.sender;
        _safeMint(msg.sender, _tokenId);

        if (_version == 1) {
            _Rewards[1] += Price * 0.8;
            _Rewards[2] += Price * 0.1;
            _DevBalance += Price * 0.1;
        } else if (_version == 2) {
            _Rewards[2] += Price * 0.8;
            _Rewards[3] += Price * 0.1;
            _DevBalance += Price * 0.1;
        } else {
            _Rewards[3] += Price * 0.8;
            _DevBalance += Price * 0.2;
        }
    }

    function distributeRewardsToWinners() public {
        uint256 index = 0;

        payable(address(this)).transfer(_Dev, _Rewards[1] / _Minted[1].length);

        while(_Minted[1][index].minter) {
            payable(address(this)).transfer(_Minted[1][index].minter, _Rewards[1] / _Minted[1].length);
        }
        index = 0;
        while(_Minted[2][index].minter) {
            payable(address(this)).transfer(_Minted[2][index].minter, _Rewards[2] / _Minted[2].length);
        }
        index = 0;
        while(_Minted[3][index].minter) {
            payable(address(this)).transfer(_Minted[3][index].minter, _Rewards[3] / _Minted[3].length);
        }
    }
}
