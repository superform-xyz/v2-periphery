# HyperLiquid Composer Interview Notes

**Date:** 2026-02-24
**Feature:** HyperLiquid Composer for UpOFT
**Interviewer:** Claude Code
**Interviewee:** cosming

---

## Context

This is Step 2 of a 3-step LZ/HyperLiquid integration process:
- **Step 1**: OFT deployment — ✅ Deployed on Base + HyperEVM
- **Step 2**: HyperLiquid Composer deployment on HyperEVM ← **THIS TICKET**
- **Step 3**: Connect market on HyperCore to OFT (separate TOK ticket)

### Background Documents Provided
- `docs/HyperEVM_Configuration_Calldata.md` - Configuration calldata for OFT pathways
- `docs/hyperliquid-composer-spec.md` - Technical analysis of Composer integration

---

## Interview Q&A

### Q1: Core Index ID Availability
**Q:** Do you have the Core Index ID for UP on HyperCore yet?
**A:** Not yet available. Spec will use placeholder, deployment blocked until Step 3 provides it.

### Q2: HyperCore Decimals
**Q:** What decimals will UP have on HyperCore (HIP-1)?
**A:** User initially asked if it would be the same as EVM (18). Initial assumption was 8 (like HYPE).

**Clarification (Post-Research):** HyperCore weiDecimals are **configurable** during HIP-1 deployment:
- Via UI: 0-8 decimals
- Via API: 0-15 decimals (full range)
- HYPE uses 8 as a specific choice, not a requirement

**Recommendation:** Use 18 decimals (same as EVM) via the API for zero precision loss and simplest integration. This decision is made during Step 3 (HIP-1 deployment).

**Constraint:** `assetDecimalDiff = EVM_decimals - Core_decimals` must be in range `[-2, 18]`.

### Q3: Contract Implementation
**Q:** Should the Composer contract be a thin wrapper or need custom logic?
**A:** Use RecoverableComposer extension for emergency fund recovery capabilities.

**RecoverableComposer provides:**
- `retrieveCoreERC20()` - Pull tokens from Composer's HyperCore balance back to asset bridge
- `retrieveCoreHYPE()` - Pull HYPE from Composer's HyperCore balance back to HYPE bridge
- `recoverEvmERC20()` - Recover ERC20 tokens stuck on HyperEVM side
- `recoverEvmNative()` - Recover native HYPE stuck on HyperEVM side

**Source:** https://github.com/LayerZero-Labs/devtools/blob/e149a722de12a8a47bf77c85895f16c3fa82d8bb/packages/hyperliquid-composer/contracts/extensions/RecoverableComposer.sol

### Q4: Ownership
**Q:** Who will own/manage the Composer contract?
**A:** Initially deployer wallet (`0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8`), then transfer ownership to MPC wallet (`0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153`).

---

## Requirements Summary

### Functional Requirements
1. Deploy HyperLiquidComposer contract on HyperEVM for UP token
2. Enable direct bridging from Base/Ethereum → HyperCore spot trading
3. Use LayerZero's compose functionality (already configured in OFT deployment)
4. Handle failed message refunds

### Non-Functional Requirements
1. Gas efficient - must work within 1,000,000 compose gas limit
2. Security - proper access control with ownership transfer capability
3. Compatibility - must work with existing UP OFT deployment

### Technical Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Contract type | RecoverableComposer | Enables emergency fund recovery |
| Recovery address | MPC wallet | `0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153` |
| Core decimals | **TBD (recommend 18)** | Configurable during Step 3. Using 18 avoids precision loss |
| assetDecimalDiff | **TBD (0 if 18 decimals)** | `EVM_decimals - Core_decimals`, range [-2, 18] |
| Initial owner | Deployer | Transfer to MPC wallet after deployment |

### Dependencies
- **Blocking:** Core Index ID from Step 3 team
- **Non-blocking:** Asset bridge funding (can be done post-deployment)

### Risks
1. Core Index ID not available - blocks deployment
2. Asset bridge capacity - tokens locked forever if exceeded
3. Composer activation on HyperCore required

---

## Existing Infrastructure

### Deployed Contracts
| Contract | Chain | Address |
|----------|-------|---------|
| UP OFT | Base | `0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B` |
| UP OFT | HyperEVM | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` |
| UP OFT Adapter | Ethereum | `0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD` |

### Key Addresses
- MPC Wallet (Owner): `0x97b5e4a707A4D5AB4A58b2c93bc8d249a63Ff153`
- Deployer (Delegate): `0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8`
- LZ Endpoint (HyperEVM): `0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9`

### Gas Configuration
- `lzReceive`: 300,000 gas
- `lzCompose`: 1,000,000 gas (sufficient for Composer's 150k-200k requirement)
