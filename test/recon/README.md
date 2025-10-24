# Recon Invariant Testing Suite

## Usage
This test suite uses the [Chimera Framework](https://book.getrecon.xyz/writing_invariant_tests/chimera_framework.html) to allow testing using multiple fuzzers and formal verification tools. 

## Setup
Currently the test setup initally deploys a single triad of `SuperVault`, `SuperVaultStrategy` and `SuperVaultEscrow`. A new triad can be deployed and set using the `superVaultAggregator_createVault`, this allows deploying a `SuperVault` whose underlying asset uses a different decimal precision which the fuzzer can deploy via the `add_new_asset` function.

The setup also deploys three yield sources using the `YieldManager` which deploys an instance of the `MockERC4626Tester`, `MockERC5115Tester` and `MockERC7540Tester`. This can be switched as the yield source targeted by the fuzzer using the `_switchYieldSource` function. 

All hooks are currenlty deployed in the `Setup` contract and can be fetched for the currently set yield source using `_getApproveAndDepositHookForType` and `_getRedeemHookForType`. Hook validation is currently bypassed by using the `UnsafeSuperVaultAggregator` which inherits from the `SuperVaultAggregator` to always return true when hooks need to be verified.

Any functions related to modifying hook roots have been removed from the set of target functions because the hook bypassing of the hook validation step makes testing these waste fuzzing calls.


## Findings 



### Property Testing
This test suite uses assertion property tests defined for the system contracts in the [`Properties`](https://github.com/superform-xyz/v2-periphery/blob/recon-invariants/test/recon/Properties.sol) contract and in the function handlers in the [targets/ directory](https://github.com/superform-xyz/v2-periphery/tree/recon-invariants/test/recon/targets).  

See [this section](https://book.getrecon.xyz/extra/advanced.html) of the Recon book about techniques we use when writing properties and how we ensure full coverage.

#### Echidna Property Testing
To locally test properties using Echidna, run the following command in your terminal:
```shell
echidna . --contract CryticTester --config echidna.yaml
```

### Foundry Testing
Broken properties found when running Echidna can be turned into unit tests for easier debugging with [Recon's tools](https://getrecon.xyz/tools/echidna) and added to the `CryticToFoundry` contract.

```shell
forge test --match-test <reproducer-test-name> -vv
```

## Expanding Target Functions
See [this section](https://book.getrecon.xyz/writing_invariant_tests/sample_project.html#building-target-functions) of the Recon book on how to add additional target functions for testing. 

## Uploading Fuzz Job To Recon

You can offload your fuzzing job to Recon to run long duration jobs and share test results with collaborators using the [jobs page](https://getrecon.xyz/dashboard/jobs)

See the [Recon book](https://book.getrecon.xyz/using_recon/running_jobs.html) for more info on how to upload a job to the Recon web app. 