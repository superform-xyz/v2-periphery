// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title MockUp
 * @notice Mock UP token for testing without the initial lock period restrictions
 * @author Superform Foundation
 */
contract MockUp is ERC20, ERC20Permit, Ownable2Step {
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    event TokensMinted(address indexed to, uint256 amount);

    constructor(address initialOwner) ERC20("Superform", "UP") ERC20Permit("Superform") Ownable(initialOwner) {
        _mint(initialOwner, INITIAL_SUPPLY);
    }

    /**
     * @notice Allows owner to mint new tokens without restrictions (for testing)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
}
