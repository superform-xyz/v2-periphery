# Repository Analysis: HyperLiquid Composer for UP OFT

## Architecture & Structure

### Existing OFT Deployment Patterns (`script/DeployUpOFT.s.sol`)

The `DeployUpOFT.s.sol` script demonstrates the following key patterns:

1. **Deterministic Deployment**: Uses `DeterministicDeployerLib` from v2-core for CREATE2-based deterministic addresses
   - Salt generation: `keccak256(abi.encodePacked("SuperformV2", SALT_NAMESPACE, name, "v2.0"))`
   - Salt namespaces: `"TEST1.0.0"` (env=0), `"STAGING1.0.0"` (env=2), or custom (env=1)
   - Deployer address: `0x4e59b44847b379578588920cA78FbF26c0B4956C`

2. **Multi-Chain Configuration**: Already supports HyperEVM (chain ID 999, EID 30367) alongside Ethereum (chain ID 1, EID 30101) and Base (chain ID 8453, EID 30184)

3. **LayerZero Configuration Constants**:
   ```solidity
   address internal constant LZ_ENDPOINT_HYPEREVM = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
   address internal constant DVN_LZ_HYPEREVM = 0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f;
   address internal constant SEND_LIB_HYPEREVM = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
   address internal constant RECEIVE_LIB_HYPEREVM = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;
   address internal constant EXECUTOR_HYPEREVM = 0x41Bdb4aa4A63a5b2Efc531858d3118392B1A1C3d;
   ```

4. **Gas Limits**:
   - `GAS_LIMIT = 300_000` (for SEND)
   - `COMPOSE_GAS_LIMIT = 1_000_000` (for SEND_AND_CALL)

---

## LayerZero HyperLiquid Composer Contracts

### Core Composer Contract (`lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidComposer.sol`)

Key implementation details:

1. **Constructor Parameters**:
   ```solidity
   constructor(address _oft, uint64 _coreIndexId, int8 _assetDecimalDiff)
   ```
   - `_oft`: The OFT contract address on HyperEVM
   - `_coreIndexId`: HyperLiquid L1 spot index (e.g., 150 for HYPE mainnet)
   - `_assetDecimalDiff`: EVM decimals - HyperCore decimals (e.g., 18 - 8 = 10 for UP)

2. **HyperLiquid System Addresses** (from `HyperLiquidCore.sol`):
   ```solidity
   address internal constant HYPE_ASSET_BRIDGE = 0x2222222222222222222222222222222222222222;
   address internal constant HLP_CORE_WRITER = 0x3333333333333333333333333333333333333333;
   address internal constant SPOT_BALANCE_PRECOMPILE = 0x0000000000000000000000000000000000000801;
   address internal constant CORE_USER_EXISTS_PRECOMPILE = 0x0000000000000000000000000000000000000810;
   ```

3. **Compose Message Format**:
   - Length: 64 bytes
   - Format: `abi.encode(uint256 minMsgValue, address receiver)`

4. **Min Gas Requirements**:
   - `MIN_GAS() = 150_000` (without value)
   - `MIN_GAS_WITH_VALUE() = 200_000` (with native value)

---

## Example Implementation (`lib/devtools/examples/oft-hyperliquid/contracts/MyHyperLiquidComposer.sol`)

The minimal implementation pattern:

```solidity
contract MyHyperLiquidComposer is HyperLiquidComposer {
    constructor(
        address _oft,
        uint64 _hlIndexId,
        int8 _assetDecimalDiff
    ) HyperLiquidComposer(_oft, _hlIndexId, _assetDecimalDiff) {}
}
```

---

## Extension Options

Three extension patterns available in `lib/devtools/packages/hyperliquid-composer/contracts/extensions/`:

1. **RecoverableComposer**: Adds emergency recovery functionality with `RECOVERY_ADDRESS`
   - `retrieveCoreERC20()`, `retrieveCoreHYPE()`: Recover from HyperCore
   - `recoverEvmERC20()`, `recoverEvmNative()`: Recover from HyperEVM

2. **FeeToken**: For tokens that can pay activation fees (USDC, USDT0)
   - Automatically deducts activation fee from transfer amount
   - `activationFee()` returns 1 complete core token for USD stables

3. **PreFundedFeeAbstraction**: Dynamic fee calculation using spot prices

---

## UP Token Contracts (`src/UP/`)

1. **UpOFT.sol** (for Base and HyperEVM):
   - Extends `OFT` from LayerZero
   - Constructor: `constructor(address _lzEndpoint, address _delegate)`
   - Token name: "Superform", symbol: "UP"
   - Includes `sweepNative()` function for owner

2. **UpOFTAdapter.sol** (for Ethereum):
   - Extends `OFTAdapter` from LayerZero
   - Hardcoded canonical UP token: `0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33`

---

## Deployment Output Patterns (`script/output/prod/`)

Current deployed addresses:

| Chain | Contract | Address |
|-------|----------|---------|
| Ethereum (1) | UpOFTAdapter | `0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD` |
| Base (8453) | UpOFT | `0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B` |
| HyperEVM (999) | UpOFT | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` |

JSON output format:
```json
{
  "UpOFT": "0x642fFC3496AcA19106BAB7A42F1F221a329654fe"
}
```

---

## Code Conventions

1. **Solidity Version**: `0.8.30` (from foundry.toml)
2. **License**: UNLICENSED for scripts, MIT for contracts
3. **Import Style**: Explicit named imports
4. **Error Handling**: Custom errors (e.g., `NATIVE_TRANSFER_FAILED()`, `ADDRESS_NOT_VALID()`)
5. **Constants**: SCREAMING_SNAKE_CASE, `internal constant` visibility
6. **Immutables**: SCREAMING_SNAKE_CASE
7. **Formatting**: 4-space tabs, 120 char line length, bracket spacing

---

## Recommendations

1. **Create a new contract** `src/UP/UpHyperLiquidComposer.sol` following the example pattern
2. **Extend with RecoverableComposer** for emergency fund recovery capabilities
3. **Add deployment functions** to `DeployUpOFT.s.sol` for the composer
4. **Use deterministic deployment** with same salt namespace pattern
5. **Output to** `script/output/prod/999/UpOFTComposer-latest.json`
6. **Test with precompile mocks** following patterns in the devtools test suite
