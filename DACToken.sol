// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Compatible with OpenZeppelin Contracts ^5.0.0
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {IDACAuthority} from "./IDACAuthority.sol";
import {DACAccessManaged} from "./DACAccessManaged.sol";
import {IDACToken} from "./IDACToken.sol";

//    ____    ______  ______   ____     __                                       ___                    
//   /\  _`\ /\  _  \/\__  _\ /\  _`\  /\ \                           __        /\_ \                   
//   \ \ \/\ \ \ \L\ \/_/\ \/ \ \ \/\_\\ \ \___   _ __   ___     ___ /\_\    ___\//\ \      __    ____  
//    \ \ \ \ \ \  __ \ \ \ \  \ \ \/_/_\ \  _ `\/\`'__\/ __`\ /' _ `\/\ \  /'___\\ \ \   /'__`\ /',__\ 
//     \ \ \_\ \ \ \/\ \ \_\ \__\ \ \L\ \\ \ \ \ \ \ \//\ \L\ \/\ \/\ \ \ \/\ \__/ \_\ \_/\  __//\__, `\
//      \ \____/\ \_\ \_\/\_____\\ \____/ \ \_\ \_\ \_\\ \____/\ \_\ \_\ \_\ \____\/\____\ \____\/\____/
//       \/___/  \/_/\/_/\/_____/ \/___/   \/_/\/_/\/_/ \/___/  \/_/\/_/\/_/\/____/\/____/\/____/\/___/  

/**
 * @title DACToken
 * @notice Central ERC-20 token of the Decentralized AI Chronicles Ecosystem (DAC Ecosystem).
 * @dev Implements ERC-20 with capped supply, minting, burning, and permit functionality.
 * The token is intended to be a utility token for the DAC Ecosystem,
 * enabling users to manage their NFTs and participate in the ecosystem's growth.
 */
contract DACToken is ERC20Capped, ERC20Burnable, ERC20Permit, DACAccessManaged, IDACToken {
    /**
     * @notice Deploys the DACToken contract.
     * @param initialAuthority The address of the initial authority of the contract.
     * @param maxSupply The maximum token supply, capped and cannot be exceeded.
     * @param initialSupply The initial supply of tokens to mint to the deployer.
     */
    constructor(address initialAuthority, uint256 maxSupply, uint256 initialSupply)
        ERC20("DAC Ecosystem Token", "DAC")
        ERC20Capped(maxSupply)
        ERC20Permit("DACToken")
        DACAccessManaged(IDACAuthority(initialAuthority))
    {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @inheritdoc IDACToken
     */
    function mint(address to, uint256 amount) public override onlyTreasury {
        _mint(to, amount);
    }

    /**
     * @inheritdoc IDACToken
     */
    function burn(uint256 value) public override(IDACToken, ERC20Burnable) {
        super.burn(value);
    }

    /**
     * @inheritdoc ERC20Capped
     */
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._update(from, to, amount);
    }
}
