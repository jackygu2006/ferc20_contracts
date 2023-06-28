// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./InscriptionV3.sol";
import "./libs/String.sol";
import "./libs/TransferHelper.sol";
import "./DeployContracts.sol";
import "./interfaces/IInitialFairOffering.sol";
import "./interfaces/IInscriptionFactory.sol";

contract InscriptionFactory is Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _inscriptionNumbers;

    uint8 public minTickSize = 4;                   // tick(symbol) min length
    uint8 public maxTickSize = 5;                   // tick(symbol) max length
    uint128 public baseFee = 500000000000000;       // Will charge 0.0005 ETH as extra min tip from the second time of mint in the frozen period. And this tip will be double for each mint.
    uint16 public fundingCommission = 100;       // commission rate of fund raising, 100 means 1%
    address public whitelistContract;

    mapping(uint256 => IInscriptionFactory.Token) public inscriptions; // key is inscription id, value is token data
    mapping(string => uint256) private ticks;       // Key is tick, value is inscription id
    mapping(address => bool) public stockTicks;     // check if tick is occupied

    event DeployInscription(
        uint256 indexed id, 
        string tick, 
        string name, 
        uint256 cap, 
        uint256 limitPerMint, 
        address inscriptionAddress, 
        uint256 timestamp
    );

    address public weth;

    constructor(
        address _weth
    ) {
        // The inscription id will be from 1, not zero.
        _inscriptionNumbers.increment();
        weth = _weth;
    }

    // Let this contract accept ETH as tip
    receive() external payable {}
    
    function deploy(
        string memory   _name,
        string memory   _tick,
        string memory   _logoUrl,
        uint128         _cap,
        uint128         _limitPerMint,
        uint32          _maxMintSize,               // The max lots of each mint
        uint40          _freezeTime,                // Freeze seconds between two mint, during this freezing period, the mint fee will be increased 
        address         _onlyContractAddress,       // Only the holder of this asset can mint, optional
        uint128         _onlyMinQuantity,           // The min quantity of asset for mint, optional
        uint128         _crowdFundingRate,          // Eth cost for one rollup
        bool            _isWhitelist,
        bool            _isIFOMode,
        uint16          _liquidityTokenPercent,     // TLR(token liquidity ratio) 5000 means 50%
        uint16          _liquidityEtherPercent      // ELR(Ethereum liquidity ratio) 
    ) public returns (address _inscriptionAddress) {
        require(_liquidityTokenPercent >= 0 && _liquidityTokenPercent <= 10000, "token percent 0-10000");
        require(_liquidityEtherPercent >= 0 && _liquidityEtherPercent <= 10000, "ether percent 0-10000");
        uint256 _len = String.strlen(_tick);
        require(_len <= maxTickSize && _len >= minTickSize, "Tick lenght not right");
        require(_cap >= _limitPerMint, "Limit per mint exceed cap");
        require(!_isWhitelist || (_isWhitelist && whitelistContract != address(0x0)), "whitelist can not be zero");

        _tick = String.toLower(_tick);
        (IInscriptionFactory.Token memory token, ) = getIncriptionByTick(_tick);
        require(!stockTicks[token.addr], "tick is in stock");
        require(token.addr == address(0x0), "tick is existed");

        // TO DO: call it through Dock contract 
        // If IFO mode
        address _ifoContractAddress = address(0x0);
        if(_isIFOMode) {
            // Create IFO contract
            _ifoContractAddress = DeployIFOContract.deploy(
                address(this),
                weth
            );
        }

        // Create inscription contract
        uint64 _inscriptionId = uint64(_inscriptionNumbers.current());
        _inscriptionAddress = DeployInscriptionContract.deploy(
            _inscriptionId,
            _name, 
            _tick, 
            _cap, 
            _limitPerMint, 
            _maxMintSize,
            _freezeTime,
            _onlyContractAddress,
            _onlyMinQuantity,
            baseFee,
            fundingCommission,
            _crowdFundingRate,
            _isWhitelist ? whitelistContract : address(0x0),
            _isIFOMode,
            _liquidityTokenPercent,
            _ifoContractAddress,
            address(this)
        );

        // Set inscriptions data
        inscriptions[_inscriptionId] = IInscriptionFactory.Token(
            _cap, 
            _limitPerMint, 
            _onlyContractAddress,
            _maxMintSize,
            _inscriptionId,
            _onlyMinQuantity,
            _crowdFundingRate,
            _inscriptionAddress,
            _freezeTime,
            uint40(block.timestamp),
            _liquidityTokenPercent,
            msg.sender,
            _liquidityEtherPercent,
            _tick, 
            _name, 
            _ifoContractAddress,
            _isIFOMode,
            _isWhitelist,
            _logoUrl
        );
        ticks[_tick] = _inscriptionId;

        // Run initialize function of IFO contract, must after inscriptions data is set.
        if(_isIFOMode) {
            IInitialFairOffering(_ifoContractAddress).initialize(
                inscriptions[_inscriptionId]
            );
        }

        _inscriptionNumbers.increment();
        emit DeployInscription(_inscriptionId, _tick, _name, _cap, _limitPerMint, _inscriptionAddress, block.timestamp);
    }

    function getInscriptionAmount() public view returns(uint256) {
        return _inscriptionNumbers.current() - 1;
    }

    function getIncriptionIdByTick(string memory _tick) public view returns(uint256) {
        return ticks[String.toLower(_tick)];
    }

    function getIncriptionById(uint256 _id) public view returns(IInscriptionFactory.Token memory, uint256) {
        IInscriptionFactory.Token memory token = inscriptions[_id];
        return (token, Inscription(token.addr).totalSupply());
    }

    function getIncriptionByTick(string memory _tick) public view returns(IInscriptionFactory.Token memory tokens, uint256 totalSupplies) {
        IInscriptionFactory.Token memory token = inscriptions[getIncriptionIdByTick(_tick)];
        uint256 id = getIncriptionIdByTick(String.toLower(_tick));
        if(id > 0) {
            tokens = inscriptions[id];
            totalSupplies = Inscription(token.addr).totalSupply();
        }
    }

    function getInscriptionAmountByType(uint256 _type) public view returns(uint256) {
        require(_type < 3, "type is 0-2");
        uint256 count = 0;
        for(uint256 i = 1; i <= getInscriptionAmount(); i++) {
            (IInscriptionFactory.Token memory _token, uint256 _totalSupply) = getIncriptionById(i);
            if(_type == 1 && _totalSupply == _token.cap) continue;
            else if(_type == 2 && _totalSupply < _token.cap) continue;
            else count++;
        }
        return count;
    }
    
    // Fetch inscription data by page no, page size, type and search keyword
    function getIncriptions(
        uint256 _pageNo, 
        uint256 _pageSize, 
        uint256 _type // 0- all, 1- in-process, 2- ended
    ) public view returns(
        IInscriptionFactory.Token[] memory, 
        uint256[] memory
    ) {
        // if _searchBy is not empty, the _pageNo and _pageSize should be set to 1
        require(_type < 3, "type is 0-2");
        uint256 totalInscription = getInscriptionAmount();
        uint256 pages = (totalInscription - 1) / _pageSize + 1;
        require(_pageNo > 0 && _pageSize > 0 && pages > 0 && _pageNo <= pages, "Params wrong");

        IInscriptionFactory.Token[] memory inscriptions_ = new IInscriptionFactory.Token[](_pageSize);
        uint256[] memory totalSupplies_ = new uint256[](_pageSize);

        IInscriptionFactory.Token[] memory _inscriptions = new IInscriptionFactory.Token[](totalInscription);
        uint256[] memory _totalSupplies = new uint256[](totalInscription);

        uint256 index = 0;
        for(uint256 i = 1; i <= totalInscription; i++) {
            (IInscriptionFactory.Token memory _token, uint256 _totalSupply) = getIncriptionById(i);
            if((_type == 1 && _totalSupply == _token.cap) || (_type == 2 && _totalSupply < _token.cap)) continue; 
            else {
                _inscriptions[index] = _token;
                _totalSupplies[index] = _totalSupply;
                index++;
            }
        }

        for(uint256 i = 0; i < _pageSize; i++) {
            uint256 id = (_pageNo - 1) * _pageSize + i;
            if(id < index) {
                inscriptions_[i] = _inscriptions[id];
                totalSupplies_[i] = _totalSupplies[id];
            } else break;
        }

        return (inscriptions_, totalSupplies_);
    }

    // Update inscription logo
    function updateInscriptionLogoUrl(uint256 _id, string memory _logoUrl) public {
        IInscriptionFactory.Token storage _token = inscriptions[_id];
        require(_token.deployer == msg.sender, "only deployer can update");
        _token.logoUrl = _logoUrl;
    }

    // Withdraw the ETH tip from the contract
    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        require(_amount <= payable(address(this)).balance);
        TransferHelper.safeTransferETH(_to, _amount);
    }

    // Update base fee
    function updateBaseFee(uint128 _fee) public onlyOwner {
        baseFee = _fee;
    }

    // Update funding commission
    function updateFundingCommission(uint16 _rate) public onlyOwner {
        require(_rate >= 0 && _rate <= 10000, "shoule be 0-10000");
        fundingCommission = _rate;
    }

    // Update character's length of tick
    function updateTickSize(uint8 _minSize, uint8 _maxSize) public onlyOwner {
        maxTickSize = _maxSize;
        minTickSize = _minSize;
    }

    // update stock tick
    function updateStockTick(address _addr, bool _status) public onlyOwner {
        stockTicks[_addr] = _status;
    }

    // Update whitelist
    function updateWhitelist(address _whitelist) public onlyOwner {
        whitelistContract = _whitelist;
    }

    // Upgrade from v1 to v2
    function batchUpdateStockTick(address[] memory v1StockAddresses, bool status) public onlyOwner {
        for(uint256 i = 0; i < v1StockAddresses.length; i++) {
            updateStockTick(v1StockAddresses[i], status);
        }
    }

    // ######
    function deployTest(string memory _tick, bool _isIFOMode, uint40 _freezeTime, uint128 _limitPerMint, uint16 _liquidityTokenPercent) public {
        deploy(
            "Test#01",
            _tick,
            "QmQUw15DiQKSfqKKUWDgTdeBHc19K1ByqLkx3SZWkduHUK",
            100000 ether,   // 100,000
            _limitPerMint,     // 1000 * 10^18
            10,      // Mint size
            _freezeTime,    // freezeTime
            address(0x0),   // onlyContractAddress
            0,  // onlyMinQuantity
            _isIFOMode ? 1 ether : 0,  // crowdFundintRate
            false, // isWhitelist
            _isIFOMode, // isIFOMode
            _isIFOMode ? _liquidityTokenPercent : 0, // liquidityTokenPercent
            _isIFOMode ? 8000 : 0 // liquidityEtherPercent
        );
    }
}
// 10000000000000000000  ifo费用
// 100000000000000000 ETH,打到factory的佣金
//  9900000000000000000  打到ifo合约的weth，数据正确，扣除了1%手续费
// 5539_565217391304347820 打到ifo合约的test2
// 12330_000000000000000000 打给用户

// 8258_372093023255813950