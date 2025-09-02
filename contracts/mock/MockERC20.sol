// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Mock ERC20 token
 * @notice Mock contract for ERC20 tokens and WETH
 */
contract MockERC20 is ERC20 {
    bool public allowZeroTransfer;
    uint8 _dec;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 dec,
        uint256 supply
    ) ERC20(tokenName, tokenSymbol) {
        _dec = dec;
        if (supply > 0) {
            _mint(msg.sender, supply * (10 ** dec));
        }
    }

    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf(msg.sender) >= wad, "Not enough balance");
        _burn(msg.sender, wad);
        payable(msg.sender).transfer(wad);
    }

    function transfer(address dst, uint256 wad) public override onlyPayloadSize(2 * 32) returns (bool) {
        return super.transfer(dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public override onlyPayloadSize(3 * 32) returns (bool) {
        return super.transferFrom(src, dst, wad);
    }

    function approve(address usr, uint256 wad) public override onlyPayloadSize(2 * 32) returns (bool) {
        return super.approve(usr, wad);
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function setAllowZeroTransfer(bool value) public {
        allowZeroTransfer = value;
    }

    function decimals() public view override returns (uint8) {
        return _dec;
    }
}
