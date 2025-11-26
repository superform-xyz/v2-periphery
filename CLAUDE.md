# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Claude Master Agent


### Rules
- Before you do any work, MUST view files in .claude/sessions/context_session_x.md file to get the full context (x being the id of the session we are operate, if file doesn't exist, then create one)
- context_session_x.md should contain most of context of what we did, overall plan, and sub agents will continously add context to the file
- After you finish the work, MUST update the . claude/sessions/context_session_x.md file to make sure others can get full context of what you did

### While implementing
- You should update the session as you work.
- After you complete tasks in the plan, you should update and append detailed descriptions of the changes you made, so following tasks can be easily hand over to other sub-agents and engineers.

## Sub Agents

### Access and purpose
You have access to 1 sub-agent:
- `solidity-master`

Sub agents will do research about the implementation, but you will do the actual implementation;
When passing task to sub agent, make sure you pass the context file, e.g. 'claude/sessions/session_context_x.md',
After each sub agent finishes the work, make sure you read the related documentation they created to get full context of the plan before you start executing

### Rules
- Always in plan mode to make a plan
- After get the plan, make sure you Write the plan to '.claude/sessions/session_context_x.md'
- The plan should be a detailed implementation plan and the reasoning behind them, as well as tasks broken down.
- If the task require external knowledge or certain package, also research to get latest knowledge (Use Task tool for research)
- Don't over plan it, always think MVP.
- Once they write the plan, firstly ask me, the Master Claude, to review it. Do not continue until I approve the plan.

## Commands

### Building & Testing
- `forge build` - Build all contracts
- `make ftest` - Run all tests (requires RPC configuration in Makefile)
- `make ftest-ci` - Run tests with verbose output for CI (10 parallel jobs)
- `make coverage` - Generate coverage report using lcov format
- `make coverage-genhtml` - Generate HTML coverage report (excludes vendor and test files)

### Development Workflow
- `make forge-test TEST=<test_name>` - Run specific test via Makefile
- `make forge-script SCRIPT=<script_name>` - Run forge script via Makefile

### Specialized Testing
- `make test-integration` - Run cross-chain execution tests
- `make test-gas-report-user` - Generate gas usage report for single user
- `make test-gas-report-2vaults` - Gas report for two vault operations
- `make test-gas-report-3vaults` - Gas report for three vault operations

### Dependencies
Install dependencies in submodules:
```bash
cd lib/v2-core/lib/modulekit && pnpm install
cd lib/v2-core/lib/safe7579 && yarn 
cd lib/v2-core/lib/nexus && yarn
```

## Architecture

### Core System Components

Superform v2 Periphery is a suite of products built on top of the Superform core contracts, providing user-facing savings wrappers, validator-secured vault systems, and governance infrastructure.

The periphery consists of the following components:

- **SuperAssets**: Meta-vault token implementation with incentive mechanisms
- **SuperVaults**: Validator-secured ERC7540 vault system with flexible strategies
- **VaultBank**: Chain-specific deposit contracts for cross-chain asset management
- **UP Token & Governance**: Protocol token and governance infrastructure
- **SuperBank**: Protocol fee and resource coordination
- **SuperGovernor**: Governance implementation and contract registry

### Repository Structure

```
src/
├── SuperAsset/         # Meta-vault token implementation
│   ├── SuperAsset.sol
│   ├── IncentiveCalculationContract.sol
│   └── IncentiveFundContract.sol
├── SuperVault/         # Validator-secured vault system
│   ├── SuperVault.sol
│   ├── SuperVaultAggregator.sol
│   ├── SuperVaultEscrow.sol
│   └── SuperVaultStrategy.sol
├── UP/                 # Protocol token implementation
│   ├── Up.sol
│   └── UpDistributor.sol
├── VaultBank/          # Chain-specific deposit contracts
│   ├── VaultBank.sol
│   ├── VaultBankSource.sol
│   └── VaultBankDestination.sol
├── Bank.sol            # Abstract hook execution contract
├── SuperBank.sol       # Protocol fee and resource coordination
├── SuperGovernor.sol   # Governance implementation
├── interfaces/         # Interface definitions
├── libraries/          # Utility libraries
└── oracles/           # Price feed implementations
```

### Key Components Overview

**SuperAssets System:**
- Meta-vault tokens that package multiple SuperVault positions behind ERC-20 tokens
- Oracle-priced swaps with incentive mechanisms for rebalancing
- Circuit breakers for price feed monitoring and risk management
- Energy-based incentive calculations using weighted deviation from target allocations

**SuperVaults System:**
- Validator-secured ERC7540 vaults with arbitrary hook-based yield strategies
- Dual system architecture separating operational costs (upkeep) from economic security (stakes)
- Hook validation system with Merkle proofs and veto mechanisms
- Strategist management with timelocks and governance oversight

**VaultBank System:**
- Cross-chain asset transfers using Polymer for secure messaging
- SuperPosition tokens as receipt tokens for locked collateral
- Proof validation for cross-chain operations
- Nonce management to prevent replay attacks

**Governance & Coordination:**
- UP token for utility and governance participation
- SuperGovernor as central registry with role-based access control
- SuperBank for protocol revenue distribution and hook execution
- Timelock mechanisms for security-critical operations

### Security Considerations

**Core Security Features:**
- Reentrancy protection via OpenZeppelin ReentrancyGuard
- Role-based access control throughout the system
- Timelock mechanisms for critical parameter changes
- Circuit breakers for oracle price deviations
- Merkle proof validation for hook execution
- Cross-chain proof validation using Polymer

**Known Risk Areas:**
- Strategist trust model in SuperVaults (mitigated by stakes and timelocks)
- Cross-chain proof validation complexity (mitigated by Polymer integration)
- Oracle dependencies for pricing (mitigated by circuit breakers)
- Incentive calculation complexity in SuperAssets (mitigated by mathematical review)

### Development Environment Setup

**Prerequisites:**
- Foundry (forge, cast)
- Node.js with pnpm and yarn
- Git for submodule management
- RPC endpoints for testing (configured in Makefile or .env)

**Key Configuration Files:**
- `foundry.toml` - Solidity compiler settings, remappings, profiles
- `Makefile` - Build scripts and RPC configuration
- `.env.example` - Environment variable template

### Testing Structure
- `test/unit/` - Unit tests for individual components
- `test/integration/` - Cross-chain execution tests
- `test/mocks/` - Mock contracts for testing
- Uses Foundry's testing framework with fuzzing support
- Comprehensive coverage requirements for all components

### Code Style Guidelines
- Solidity 0.8+ with explicit visibility modifiers
- NatSpec comments for all public/external functions
- Custom errors instead of revert strings
- Comprehensive events for state changes
- Checks-Effects-Interactions pattern for security
- Use of OpenZeppelin libraries and patterns

### Protocol Overview
Superform v2 Periphery extends the core protocol with user-facing products that provide:
- Simplified yield farming through meta-vault tokens
- Validator-secured vault strategies with flexible execution
- Cross-chain asset management and coordination
- Decentralized governance and protocol coordination
- Economic incentives for proper system behavior

The periphery system is designed to handle significant value while maintaining security, efficiency, and user experience through modular architecture and comprehensive risk management.