// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SendParam, MessagingFee, MessagingReceipt, OFTReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

/// @notice Minimal mock OFT for UpHyperLiquidComposer tests.
/// @dev Implements the subset of OFT/OAppCore interfaces that HyperLiquidComposer reads:
///      endpoint(), token(), and send() (for refundToSrc).
contract MockOFTForComposer is ERC20 {
    address public immutable lzEndpoint;

    /// @dev Tracks the last send() call for test assertions
    SendParam public lastSendParam;
    uint256 public lastMsgValue;
    bool public sendCalled;

    constructor(string memory _name, string memory _symbol, address _endpoint) ERC20(_name, _symbol) {
        lzEndpoint = _endpoint;
    }

    /// @dev IOAppCore.endpoint() — returns the LayerZero endpoint address
    function endpoint() external view returns (address) {
        return lzEndpoint;
    }

    /// @dev IOFT.token() — the underlying ERC20 (self for native OFTs)
    function token() external view returns (address) {
        return address(this);
    }

    /// @dev IOFT.send() — mock that records the call and burns tokens instead of bridging
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata,
        address
    )
        external
        payable
        returns (MessagingReceipt memory, OFTReceipt memory)
    {
        lastSendParam = _sendParam;
        lastMsgValue = msg.value;
        sendCalled = true;

        // Burn the tokens being "sent" so balance checks work
        if (_sendParam.amountLD > 0) {
            _burn(msg.sender, _sendParam.amountLD);
        }

        return (
            MessagingReceipt({ guid: bytes32(0), nonce: 0, fee: MessagingFee(0, 0) }),
            OFTReceipt({ amountSentLD: _sendParam.amountLD, amountReceivedLD: _sendParam.amountLD })
        );
    }

    /// @dev Mint tokens for testing
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
