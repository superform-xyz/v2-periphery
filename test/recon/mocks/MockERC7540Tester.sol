// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockERC20} from "@recon/MockERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract ERC7575 is MockERC20 {
    MockERC20 public immutable asset;

    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    constructor(MockERC20 _asset) MockERC20("MockERC7540Tester", "M7540", 18) {
        asset = _asset;
    }

    function share() external view returns (address shareTokenAddress) {
        return address(this);
    }

    function totalAssets() public view virtual returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function convertToShares(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function maxDeposit(address) public pure virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public pure virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    function previewDeposit(
        uint256 assets
    ) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    function previewWithdraw(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function previewRedeem(
        uint256 shares
    ) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual returns (uint256 shares) {
        shares = previewDeposit(assets);
        asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public virtual returns (uint256 assets) {
        assets = previewMint(shares);
        asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }
}

contract MockERC7540Tester is ERC7575, IERC165 {
    event DepositRequest(
        address indexed controller,
        address indexed owner,
        uint256 indexed requestId,
        address sender,
        uint256 assets
    );
    event RedeemRequest(
        address indexed controller,
        address indexed owner,
        uint256 indexed requestId,
        address sender,
        uint256 shares
    );
    event OperatorSet(
        address indexed controller,
        address indexed operator,
        bool approved
    );

    struct DepositRequestStruct {
        uint256 assets;
        address controller;
        address owner;
        bool fulfilled;
        bool canceled;
    }

    struct RedeemRequestStruct {
        uint256 shares;
        address controller;
        address owner;
        bool fulfilled;
        bool canceled;
    }

    uint256 private _nextRequestId = 1;

    mapping(uint256 => DepositRequestStruct) public depositRequests;
    mapping(uint256 => RedeemRequestStruct) public redeemRequests;
    mapping(address => mapping(address => bool)) public operators;
    mapping(uint256 => bool) public pendingCancelDeposit;
    mapping(uint256 => bool) public pendingCancelRedeem;

    uint256 public yieldMultiplier = 10000; // 100% in basis points
    uint256 private constant MAX_BPS = 10000;
    uint256 public totalLosses;
    uint256 public totalGains;
    uint256 public lossOnWithdraw;

    constructor(address _asset) ERC7575(MockERC20(_asset)) {}

    // Operator Management
    function setOperator(
        address operator,
        bool approved
    ) external returns (bool) {
        operators[msg.sender][operator] = approved;
        emit OperatorSet(msg.sender, operator, approved);
        return true;
    }

    function isOperator(
        address controller,
        address operator
    ) external view returns (bool) {
        return operators[controller][operator];
    }

    // Async Deposit Flow
    function requestDeposit(
        uint256 assets,
        address controller,
        address owner
    ) external returns (uint256 requestId) {
        requestId = _nextRequestId++;
        depositRequests[requestId] = DepositRequestStruct({
            assets: assets,
            controller: controller,
            owner: owner,
            fulfilled: false,
            canceled: false
        });

        asset.transferFrom(msg.sender, address(this), assets);
        emit DepositRequest(controller, owner, requestId, msg.sender, assets);
    }

    function pendingDepositRequest(
        uint256 requestId,
        address controller
    ) external view returns (uint256) {
        DepositRequestStruct storage request = depositRequests[requestId];
        if (
            request.controller != controller ||
            request.fulfilled ||
            request.canceled
        ) {
            return 0;
        }
        return request.assets;
    }

    function claimableDepositRequest(
        uint256 requestId,
        address controller
    ) external view returns (uint256) {
        DepositRequestStruct storage request = depositRequests[requestId];
        if (
            request.controller != controller ||
            request.fulfilled ||
            request.canceled
        ) {
            return 0;
        }
        return request.assets;
    }

    function pendingCancelDepositRequest(
        uint256 requestId,
        address controller
    ) external view returns (bool) {
        DepositRequestStruct storage request = depositRequests[requestId];
        return
            request.controller == controller && pendingCancelDeposit[requestId];
    }

    // Override deposit to handle async requests
    function deposit(
        uint256 assets,
        address receiver,
        address controller
    ) public returns (uint256 shares) {
        require(
            msg.sender == controller || operators[controller][msg.sender],
            "Not authorized"
        );

        // Find and fulfill a matching deposit request
        for (uint256 i = 1; i < _nextRequestId; i++) {
            DepositRequestStruct storage request = depositRequests[i];
            if (
                request.controller == controller &&
                !request.fulfilled &&
                !request.canceled &&
                request.assets >= assets
            ) {
                shares = previewDeposit(assets);
                request.fulfilled = true;
                _mint(receiver, shares);

                // Refund excess assets if any
                if (request.assets > assets) {
                    asset.transfer(controller, request.assets - assets);
                }

                emit Deposit(msg.sender, receiver, assets, shares);
                return shares;
            }
        }

        // Fallback to synchronous deposit if no matching request
        return super.deposit(assets, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public returns (uint256 shares) {
        shares = previewWithdraw(assets);
        if (msg.sender != owner) {
            allowance[owner][msg.sender] -= shares;
        }
        _burn(owner, shares);
        uint256 lossyAssets = assets - ((assets * lossOnWithdraw) / MAX_BPS);

        asset.transfer(receiver, lossyAssets);
        emit Withdraw(msg.sender, receiver, owner, lossyAssets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public returns (uint256 assets) {
        assets = previewRedeem(shares);
        if (msg.sender != owner) {
            allowance[owner][msg.sender] -= shares;
        }
        _burn(owner, shares);
        uint256 lossyAssets = assets - ((assets * lossOnWithdraw) / MAX_BPS);

        asset.transfer(receiver, lossyAssets);
        emit Withdraw(msg.sender, receiver, owner, lossyAssets, shares);
    }

    // Async Redeem Flow
    function requestRedeem(
        uint256 shares,
        address controller,
        address owner
    ) external returns (uint256 requestId) {
        requestId = _nextRequestId++;
        redeemRequests[requestId] = RedeemRequestStruct({
            shares: shares,
            controller: controller,
            owner: owner,
            fulfilled: false,
            canceled: false
        });

        emit RedeemRequest(controller, owner, requestId, msg.sender, shares);
    }

    function pendingRedeemRequest(
        uint256 requestId,
        address controller
    ) external view returns (uint256) {
        RedeemRequestStruct storage request = redeemRequests[requestId];
        if (
            request.controller != controller ||
            request.fulfilled ||
            request.canceled
        ) {
            return 0;
        }
        return request.shares;
    }

    function claimableRedeemRequest(
        uint256 requestId,
        address controller
    ) external view returns (uint256) {
        RedeemRequestStruct storage request = redeemRequests[requestId];
        if (
            request.controller != controller ||
            request.fulfilled ||
            request.canceled
        ) {
            return 0;
        }
        return request.shares;
    }

    function pendingCancelRedeemRequest(
        uint256 requestId,
        address controller
    ) external view returns (bool) {
        RedeemRequestStruct storage request = redeemRequests[requestId];
        return
            request.controller == controller && pendingCancelRedeem[requestId];
    }

    // Cancel Operations
    function cancelDepositRequest(
        uint256 requestId,
        address controller
    ) external {
        require(
            msg.sender == controller || operators[controller][msg.sender],
            "Not authorized"
        );
        DepositRequestStruct storage request = depositRequests[requestId];
        require(
            request.controller == controller && !request.fulfilled,
            "Invalid request"
        );

        pendingCancelDeposit[requestId] = true;
    }

    function claimCancelDepositRequest(
        uint256 requestId,
        address receiver,
        address controller
    ) external returns (uint256 assets) {
        DepositRequestStruct storage request = depositRequests[requestId];

        assets = request.assets;
        request.canceled = true;
        pendingCancelDeposit[requestId] = false;

        asset.transfer(receiver, assets);
    }

    function cancelRedeemRequest(
        uint256 requestId,
        address controller
    ) external {
        RedeemRequestStruct storage request = redeemRequests[requestId];

        pendingCancelRedeem[requestId] = true;
    }

    function claimCancelRedeemRequest(
        uint256 requestId,
        address receiver,
        address controller
    ) external returns (uint256 shares) {
        RedeemRequestStruct storage request = redeemRequests[requestId];

        shares = request.shares;
        request.canceled = true;
        pendingCancelRedeem[requestId] = false;

        _mint(receiver, shares);
    }

    // Placeholder functions for Centrifuge compatibility
    function poolId() external pure returns (uint64) {
        return 1;
    }

    function trancheId() external pure returns (bytes16) {
        return bytes16(uint128(1));
    }

    // Yield simulation functions (similar to MockERC4626Tester)
    // Primary way that 7540 vaults receive losses is on rounding in redemptions so we just simulate a loss that reduces total asset balance
    function increaseYield(uint256 increasePercentageFP4) external {
        uint256 amount = (totalAssets() * increasePercentageFP4) / MAX_BPS;
        MockERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function decreaseYield(uint256 decreasePercentageFP4) external {
        uint256 amount = (totalAssets() * decreasePercentageFP4) / MAX_BPS;
        MockERC20(asset).transfer(address(0xbeef), amount);
    }

    function simulateGain(uint256 gainAmount) external {
        MockERC20(asset).transferFrom(msg.sender, address(this), gainAmount);
        totalGains += gainAmount;
    }

    function simulateLoss(uint256 lossAmount) external {
        MockERC20(asset).transfer(address(0xbeef), lossAmount);
        totalLosses += lossAmount;
    }

    /// @dev Set the loss on withdraw as percentage of the assets being withdrawn
    function setLossOnWithdraw(uint256 _lossOnWithdraw) public {
        _lossOnWithdraw %= MAX_BPS + 1; // clamp to ensure we set a max of 100%
        lossOnWithdraw = _lossOnWithdraw;
    }

    /// @notice ERC165 interface detection
    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
