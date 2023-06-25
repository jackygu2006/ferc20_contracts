// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;

import "./libs/TransferHelper.sol";

// Token0
address constant WETH = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889; // MATIC on Mumbai

// Token1
address constant DAI = 0xf2c3816181dCFb969E99f1Bd5aF03c6F6bd4e9d5; // CPT1 on Mumbai

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract UniswapV3Liquidity is IERC721Receiver {
    IERC20 private constant dai = IERC20(DAI);
    IWETH private constant weth = IWETH(WETH);

    int24 private constant MIN_TICK = -887272; // 1.0001 ** -887272
    int24 private constant MAX_TICK = -MIN_TICK; // 1.0001 ** 887272, full range
    int24 private constant TICK_SPACING = 60;

    INonfungiblePositionManager public nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    receive() external payable {}

    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }
    mapping(uint => Deposit) public deposits;
    mapping(uint => uint) public tokenIds;
    uint tokenIdCount = 0;

    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        _createDeposit(operator, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    function mintNewPosition(
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        TransferHelper.safeTransferFrom(address(weth), msg.sender, address(this), amount0ToAdd);
        TransferHelper.safeTransferFrom(address(dai), msg.sender, address(this), amount1ToAdd);

        // Approve the position manager
        TransferHelper.safeApprove(address(weth), address(nonfungiblePositionManager), amount0ToAdd);
        TransferHelper.safeApprove(address(dai), address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: WETH,
                token1: DAI,
                fee: 3000,
                tickLower: (MIN_TICK / TICK_SPACING) * TICK_SPACING, // full range
                tickUpper: (MAX_TICK / TICK_SPACING) * TICK_SPACING,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

        _createDeposit(msg.sender, tokenId);

        if (amount0 < amount0ToAdd) {
            TransferHelper.safeApprove(address(weth), address(nonfungiblePositionManager), 0);
            uint256 refund0 = amount0ToAdd - amount0;
            TransferHelper.safeTransfer(address(weth), msg.sender, refund0);
        }

        if (amount1 < amount1ToAdd) {
            TransferHelper.safeApprove(address(dai), address(nonfungiblePositionManager), 0);
            uint256 refund1 = amount1ToAdd - amount1;
            TransferHelper.safeTransfer(address(dai), msg.sender, refund1);
        }
    }

    function collectAll(
        uint tokenId
    ) external returns (uint amount0, uint amount1) {
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

    function increaseLiquidity(
        uint tokenId,
        uint amount0ToAdd,
        uint amount1ToAdd
    ) external returns (uint128 liquidity, uint amount0, uint amount1) {
        TransferHelper.safeTransferFrom(deposits[tokenId].token0, msg.sender, address(this), amount0ToAdd);
        TransferHelper.safeTransferFrom(deposits[tokenId].token1, msg.sender, address(this), amount1ToAdd);

        TransferHelper.safeApprove(deposits[tokenId].token0, address(nonfungiblePositionManager), amount0ToAdd);
        TransferHelper.safeApprove(deposits[tokenId].token1, address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams
            memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);

        Deposit storage deposit = deposits[tokenId];
        deposit.liquidity = deposit.liquidity + liquidity;
    }

    function decreaseLiquidity(
        uint tokenId,
        uint16 ratio // If remove half liquidity, set 5000; if remove 25% liquidity, set 2500
    ) external returns (uint amount0, uint amount1) {
        require(msg.sender == deposits[tokenId].owner, "Not the owner");
        uint128 decreaseLiquidityAmount = deposits[tokenId].liquidity * ratio / 10000;

        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: decreaseLiquidityAmount,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
        // Withdraw the liquidity
        this.collectAll(tokenId);

        Deposit storage deposit = deposits[tokenId];
        deposit.liquidity = 0;
    }

    function getLiquidity(uint _tokenId) external view returns(
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

    function _createDeposit(
        address _operator, 
        uint _tokenId
    ) internal {
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

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        address recipient;
        uint deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1);

    struct IncreaseLiquidityParams {
        uint tokenId;
        uint amount0Desired;
        uint amount1Desired;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint amount0, uint amount1);

    struct DecreaseLiquidityParams {
        uint tokenId;
        uint128 liquidity;
        uint amount0Min;
        uint amount1Min;
        uint deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    struct CollectParams {
        uint tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint amount0, uint amount1);

    function positions(
        uint256 tokenId
    ) external view returns (
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
    );
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}
