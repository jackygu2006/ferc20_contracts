// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./interfaces/IInscription.sol";
import "./interfaces/IInscriptionFactory.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IWETH.sol";
import "./libs/TransferHelper.sol";
import "./libs/BytesLib.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// This contract will be created while deploying
// The liquidity can not be removed
contract InitialFairOffering {
    int24 private constant MIN_TICK = -887272;      // add liquidity with full range 
    int24 private constant MAX_TICK = -MIN_TICK;    // add liquidity with full range
    int24 private constant TICK_SPACING = 60;       // Tick space is 60
    uint24 public constant UNISWAP_FEE = 3000;

    INonfungiblePositionManager public constant nonfungiblePositionManager 
        = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    IUniswapV3Factory public uniswapV3Factory 
        = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    IWETH public weth;

    IInscriptionFactory public inscriptionFactory;
    address public constant BURN_ADDRESS = address(0x01);

    struct MintData {
        uint128 ethAmount;          // eth payed by user(deduce commission)
        uint128 tokenAmount;        // token minted by user
        uint128 tokenLiquidity;     // token liquidity saved in this contract
    }

    mapping(address => MintData) public mintData;

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }
    mapping(uint => Deposit) public deposits; // uint - tokenId of liquidity NFT
    mapping(uint => uint) public tokenIds;
    uint public tokenIdCount;

    IInscriptionFactory.Token public token;

    // This contract can be only created by InscriptionFactory contract
    constructor(
        address _inscriptionFactory,
        address _weth
    ) {
        inscriptionFactory = IInscriptionFactory(_inscriptionFactory);
        weth = IWETH(_weth);
    }

    receive() external payable {
        // Change all received ETH to WETH
        if(msg.sender != address(weth)) TransferHelper.safeTransferETH(address(weth), msg.value);
    }

    function initialize(
        IInscriptionFactory.Token memory _token
    ) public {
        // Check if the deployer has sent the liquidity ferc20 tokens
        require(address(inscriptionFactory)== msg.sender, "Only inscription factory allowed");
        require(_token.inscriptionId > 0, "token data wrong");
        token = _token;
        // _initializePool(address(weth), _token.addr, );
    }

    function _initializePool(
        address _weth,
        address _token,
        uint160 _rate // eth quantity per token
    ) private {
        address _token0 = _weth;
        address _token1 = _token;
        // TODO: 
        uint160 sqrtPriceX96 = 11111; // token quantity per weth
        if(_token0 > _token1) {
            _token0 = _token;
            _token1 = _weth;
            sqrtPriceX96 = 22222; // weth quantity per token
        }
        nonfungiblePositionManager.createAndInitializePoolIfNecessary(
            _token0,
            _token1,
            UNISWAP_FEE,
            sqrtPriceX96
        );
    }

    // Add liquidity
    function addLiquidity(
        uint16 ratio            // The ratio of balance of eths and tokens will be added to liquidity pool
    ) public {
        require(ratio > 0 && ratio <=10000, "ratio error");
        require(token.deployer == msg.sender, "Only deployer");
        require(IInscription(token.addr).totalRollups() >= maxRollups(), "mint not finished");

        // Send ether back to deployer, the eth liquidity is based on the balance of this contract. So, anyone can send eth to this contract
        uint256 balanceOfWeth = IWETH(weth).balanceOf(address(this));
        uint256 totalEthLiquidity = balanceOfWeth * token.liquidityEtherPercent / 10000; // Ex. 50ETH in contract, 80% to the pool, totalEthLiquidity = 40;

        uint256 backToDeployAmount = balanceOfWeth * (10000 - token.liquidityEtherPercent) / 10000; // Ex. 50ETH in contract, 20% to deployer
        if(backToDeployAmount > 0) {
            weth.withdraw(backToDeployAmount * ratio / 10000);  // Change WETH to ETH
            TransferHelper.safeTransferETH(token.deployer, backToDeployAmount * ratio / 10000);
        }
        // Add liquidity, LP token keep in this contract, using address(this).balance and "token.cap * _token.liquidityTokenPercent / 10000"
        uint256 totalTokenLiquidity = IInscription(token.addr).balanceOf(address(this));

        // TransferHelper.safeTransfer(address(weth), BURN_ADDRESS, totalEthLiquidity * ratio / 10000);
        // TransferHelper.safeTransfer(token.addr, BURN_ADDRESS, totalTokenLiquidity * ratio / 10000);

        address pool = uniswapV3Factory.getPool(address(weth), token.addr, UNISWAP_FEE);
        require(pool != address(0x0), "Pool not exist, create pool in uniswapV3 manually");

        _mintNewPosition(
            totalEthLiquidity * ratio / 10000, // weth amount
            totalTokenLiquidity * ratio / 10000  // ferc20 token amount
        );
    }

    function decreaseLiquidity(
        uint16 ratio
    ) public {
        // TODO
    }

    function collectFee(
        uint tokenId
    ) public returns (uint amount0, uint amount1) {
        // Anyone can call this function, and fee will be sent to deployer
        require(IInscription(token.addr).totalRollups() >= maxRollups(), "mint not finished");

        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
        _sendToOwner(tokenId, amount0, amount1);
    }

    function refund() public {
        require(mintData[msg.sender].ethAmount > 0, "you have not mint");
        require(IInscription(token.addr).totalRollups() < maxRollups(), "mint has finished");

        // check balance and allowance of tokens, if the balance or allowance is smaller than the what he/she get while do mint, the refund fail
        require(IInscription(token.addr).balanceOf(msg.sender) >= mintData[msg.sender].tokenAmount, "Your balance token not enough");
        require(IInscription(token.addr).allowance(msg.sender, address(this)) >= mintData[msg.sender].tokenAmount, "Your allowance not enough");

        // Burn the tokens from msg.sender
        TransferHelper.safeTransferFrom(token.addr, msg.sender, BURN_ADDRESS, mintData[msg.sender].tokenAmount);
        mintData[msg.sender].tokenAmount = 0;

        // Burn the token liquidity in this contract
        TransferHelper.safeTransfer(token.addr, BURN_ADDRESS, mintData[msg.sender].tokenLiquidity);
        mintData[msg.sender].tokenLiquidity = 0;

        // Refund Ether
        weth.withdraw(mintData[msg.sender].ethAmount);  // Change WETH to ETH
        TransferHelper.safeTransferETH(msg.sender, mintData[msg.sender].ethAmount);
        mintData[msg.sender].ethAmount = 0;
    }

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) public returns (bytes4) {
        _createDeposit(operator, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function getLiquidity(uint _tokenId) public view returns(
        uint96 nonce, 
        address operator, 
        address token0, 
        address token1, 
        uint24 fee, 
        int24 tickLower, 
        int24 tickUpper, 
        uint128 liquidity, 
        uint256 feeGrowthInside0LastX128, 
        uint256 feeGrowthInside1LastX128, 
        uint128 tokensOwed0, 
        uint128 tokensOwed1        
    ) {
        return nonfungiblePositionManager.positions(_tokenId);
    }

    // Call from Inscription::mint only
    function setMintData(address _addr, uint128 _ethAmount, uint128 _tokenAmount, uint128 _tokenLiquidity) public {
        require(_ethAmount > 0 && _tokenAmount > 0 && _tokenLiquidity > 0 && _addr != address(0x0), "setEtherLiquidity wrong params");
        require(msg.sender == token.addr, "Only call from inscription allowed");

        mintData[_addr].ethAmount = mintData[_addr].ethAmount + _ethAmount;
        mintData[_addr].tokenAmount = mintData[_addr].tokenAmount + _tokenAmount;
        mintData[_addr].tokenLiquidity = mintData[_addr].tokenLiquidity + _tokenLiquidity;
    }

    function maxRollups() public view returns(uint256) {
        // Because of liquidity part after each mint, the total mintable quantity will be less than cap a little bit.
        // The total mintable will be: cap * (1 - liquidityTokenPercent) / limitPerMint
        // Because of the liquidityTokenPercent is interge, the final function will be:
        // cap * (10000 - liquidityTokenPercent) / limitPerMint / 10000
        return token.cap * (10000 - token.liquidityTokenPercent) / token.limitPerMint / 10000;
    }

    function _mintNewPosition(
        uint amount0ToAdd,  // for weth
        uint amount1ToAdd   // for ferc20
        // TODO: set tickLower and tickUpper
    ) private returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        // If weth < ferc20, set token0/amount0 is weth and token1/amount1 is ferc20
        // Otherwise, set token0/amount0 is ferc20, and token1/amount1 is weth
        address _token0 = address(weth);
        address _token1 = token.addr;
        uint _amount0 = amount0ToAdd;
        uint _amount1 = amount1ToAdd;
        if(address(weth) > token.addr) {
            _token0 = token.addr;
            _token1 = address(weth);
            _amount0 = amount1ToAdd;
            _amount1 = amount0ToAdd;
        }

        // Approve the position manager
        TransferHelper.safeApprove(_token0, address(nonfungiblePositionManager), _amount0);
        TransferHelper.safeApprove(_token1, address(nonfungiblePositionManager), _amount1);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: _token0,
                token1: _token1,
                fee: UNISWAP_FEE,
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING, // full range
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: _amount0,
                amount1Desired: _amount1,
                amount0Min: 0, // TODO slipage处理
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

        _createDeposit(msg.sender, tokenId);

        if (amount0 < _amount0) {
            TransferHelper.safeApprove(_token0, address(nonfungiblePositionManager), 0);
        }

        if (amount1 < _amount1) {
            TransferHelper.safeApprove(_token1, address(nonfungiblePositionManager), 0);
        }
    }

    function _createDeposit(
        address _operator, 
        uint _tokenId
    ) private {
        (, , address token0, address token1, , , , uint128 liquidity, , , ,) = nonfungiblePositionManager.positions(_tokenId);

        if(deposits[_tokenId].owner == address(0x0)) {
            tokenIds[tokenIdCount] = _tokenId;
            tokenIdCount++;
        }

        deposits[_tokenId] = Deposit({
            owner: _operator,
            liquidity: liquidity,
            token0: token0,
            token1: token1
        });
    }

    /// @notice Transfers funds to owner of NFT
    /// @param tokenId The id of the erc721
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    function _sendToOwner(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) internal {
        // get owner of contract
        address owner = deposits[tokenId].owner;

        // send to owner
        TransferHelper.safeTransfer(deposits[tokenId].token0, owner, amount0);
        TransferHelper.safeTransfer(deposits[tokenId].token1, owner, amount1);
    }
}
