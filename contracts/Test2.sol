// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./libs/BytesLib.sol";
import "./libs/TransferHelper.sol";
import "./interfaces/IWETH.sol";

contract WETHBalance {
    IWETH weth;

    constructor(address _weth) {
        weth = IWETH(_weth);
    }

    function getWETHBalance(address _addr) external view returns(uint256) {
        return weth.balanceOf(_addr);
    }

    function getETHBalance(address _addr) external view returns(uint256) {
        return _addr.balance;
    }
}

contract WETHTest {
    IWETH weth;

    constructor(address _weth) {
        weth = IWETH(_weth);
    }

    receive() external payable {
        require(weth.totalSupply() > 0, "WETH address wrong");
        TransferHelper.safeTransferETH(address(weth), msg.value);
    }

    function getWETHBalance() external view returns(uint256) {
        return weth.balanceOf(address(this));
    }

    function getETHBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function withdraw(uint _amount) external {
        weth.withdraw(_amount);
    }
}

contract Test2 {

    enum DataType {
        None,
        Address,
        Uint8,
        Uint16,
        Uint32,
        Uint64,
        Uint96,
        Uint128,
        Uint256,
        Bytes,
        Bytes32,
        String
    }

    string public aa;
    uint8  public  bb;
    address public cc;
    address public dd;
    uint256 public ee;
    uint128 public ff;
    uint8   public gg;

    struct Type {
        uint256 len;
        DataType dataType;
    }

    mapping(address => uint256) public receiving;
    receive() external payable {
        require(msg.value > 0);
        receiving[msg.sender] = msg.value;
    }


    function concat01() public pure returns(bytes memory, Type[] memory types) {
        types = new Type[](2);
        uint256 amount = 50000000000000000000000;
        uint16 ratio = 5000;

        // 0x000000000000000000000000000000000000000000000a968163f0a57b4000001388
        bytes memory result;

        types[0] = Type(
            abi.encodePacked(amount).length,
            DataType.Uint256
        );
        result = BytesLib.concat(result, abi.encodePacked(amount));

        types[1] = Type(
            abi.encodePacked(ratio).length,
            DataType.Uint16
        );
        result = BytesLib.concat(result, abi.encodePacked(ratio));
        return (result, types);
    }

    function parseBytes(bytes memory _data) public pure returns(uint16) {
        // uint256 _amount = BytesLib.toUint256(BytesLib.slice(_data, 0, 32), 0);
        uint16 _ratio = BytesLib.toUint16(_data, 32);
        return _ratio;
    }

    function concat02() public pure returns(bytes memory, Type[] memory types) {
        types = new Type[](1);
        address deployer = 0x615b80388E3D3CaC6AA3a904803acfE7939f0399;

        // 0x615b80388e3d3cac6aa3a904803acfe7939f0399
        bytes memory result;

        types[0] = Type(
            abi.encodePacked(deployer).length,
            DataType.Address
        );
        result = BytesLib.concat(result, abi.encodePacked(deployer));

        return (result, types);
    }

    function concatToBytes() public pure returns(bytes memory, Type[] memory types) {
        types = new Type[](7);
        string  memory a = unicode"Hello 中国";
        uint8   b = 1;
        address c = 0x14eC761DefCa418309488e20963B3070152DDc3E;
        address d = address(0x0);
        uint256 e = 423423243424153456536523;
        uint128 f = 423436564208098524;
        uint8   g = 32;

        // 0x48656c6c6f20e4b8ade59bbd
        // 01
        // 14ec761defca418309488e20963b3070152ddc3e
        // 0000000000000000000000000000000000000000
        // 0000000000000000000000000000000000000000000059a9d1ecd5c6c522ebcb
        // 000000000000000005e0594fca891cdc
        // 20

        bytes memory result;

        types[0] = Type(
            bytes(a).length,
            DataType.String
        );
        result = BytesLib.concat(result, bytes(a));

        types[1] = Type(
            abi.encodePacked(b).length,
            DataType.Uint8
        );
        result = BytesLib.concat(result, abi.encodePacked(b));

        types[2] = Type(
            abi.encodePacked(c).length,
            DataType.Address
        );
        result = BytesLib.concat(result, abi.encodePacked(c));

        types[3] = Type(
            abi.encodePacked(d).length,
            DataType.Address
        );
        result = BytesLib.concat(result, abi.encodePacked(d));

        types[4] = Type(
            abi.encodePacked(e).length,
            DataType.Uint256
        );
        result = BytesLib.concat(result, abi.encodePacked(e));

        types[5] = Type(
            abi.encodePacked(f).length,
            DataType.Uint128
        );
        result = BytesLib.concat(result, abi.encodePacked(f));

        types[6] = Type(
            abi.encodePacked(g).length,
            DataType.Uint8
        );
        result = BytesLib.concat(result, abi.encodePacked(g));

        // 12,12,
        // 1,1,
        // 20,2,
        // 20,2,
        // 32,9,
        // 16,8,
        // 1,3
        return (result, types);
    }

    function parseBytes() public {
        (bytes memory result, Type[] memory types) = concatToBytes();

        uint256 pos = 0;
        aa = BytesLib.toString(BytesLib.slice(result, pos, types[0].len));

        pos = pos + types[0].len;
        bb = BytesLib.toUint8(BytesLib.slice(result, pos, types[1].len), 0);

        pos = pos + types[1].len;
        cc = BytesLib.toAddress(BytesLib.slice(result, pos, types[2].len), 0);

        pos = pos + types[2].len;
        dd = BytesLib.toAddress(BytesLib.slice(result, pos, types[3].len), 0);

        pos = pos + types[3].len;
        ee = BytesLib.toUint256(BytesLib.slice(result, pos, types[4].len), 0);

        pos = pos + types[4].len;
        ff = BytesLib.toUint128(BytesLib.slice(result, pos, types[5].len), 0);

        pos = pos + types[5].len;
        gg = BytesLib.toUint8(BytesLib.slice(result, pos, types[6].len), 0);
    }

}