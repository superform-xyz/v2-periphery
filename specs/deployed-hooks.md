# Deployment Addresses

Superform Core v2 contracts are deployed at deterministic addresses across Ethereum, Base, Optimism, Arbitrum, BNB, Polygon, Avalanche, Unichain, HyperEVM, Berachain, Sonic, Gnosis, and Worldchain.

## Core Contracts

### Infrastructure

| Contract | Chains | Address |
|----------|--------|---------|
| FlatFeeLedger | All | `0xAb56d09Ad9975116fCeb14970F2fFb3bB0ad683E` |
| Nexus | All | `0xA3AA31f8d4Da6005aAfB0d61e5012a64d15F5B3A` |
| NexusAccountFactory | All | `0x4153Db38136E74a88A77b51a955A88823820C050` |
| NexusBootstrap | All | `0x5eBeb4d51723bA345080D81bBF178D93E84bC9BE` |
| NexusProxy | All | `0x8a3A6698C3D142b9dAD80F114947d46671A5290E` |
| SuperBundler | All | `0x1101eec94dd79bee1b5a77b96c15ac24a4691e2e` |
| SuperDestinationExecutor | All | `0x6ac58e854798D4aae5989B18ad5a1C0fF17817EF` |
| SuperDestinationValidator | All | `0xADEFF5A0684392C4c273a9C638d1dB8c5dfd0098` |
| SuperExecutor | All | `0x9cC8EDCC41154aaFC74D261aD3D87140D21F6281` |
| SuperLedger | All | `0x04916bB42564CdED96E10F55C059d65E4FCb1Be6` |
| SuperLedgerConfiguration | All | `0x2e2D71289CBA19f831856f85DEC7f194B0165e69` |
| SuperNativePaymaster | All | `0x2288C49689c2CceD5C5bdd74Ac3b775E61a7A532` |
| SuperOracle | ETH, Base | `0x8943128DbAb4279D561654dEED2930Bb975AA070` |
| SuperOracle | HyperEVM | `0x40c72A5667572641Ca428a2DFa8456EBD4623c10` |
| SuperSenderCreator | All | `0xBC6FB94D2f10A3B4349F592FFA80C4B7C97C1799` |
| SuperValidator | All | `0xB46b4773C5F53FF941533F5dfEFFD0713f5f9f8E` |
| SuperYieldSourceOracle | All | `0x98F0682ef39dE9cd6028D91090Be6EdAE129f52D` |

### Oracles

| Contract | Chains | Address |
|----------|--------|---------|
| ERC4626YieldSourceOracle | All | `0x2412A5d7261995b49D1F3a731F8452641B916994` |
| ERC5115YieldSourceOracle | All | `0x53Ab533023db9f16e47774109D4Ba57b06A52b10` |
| FixedPriceOracle | ETH, Base, HyperEVM | `0x66b30A0Dda7F868796ADC3d70232950D65F3565c` |
| PendlePTAmortizedOracle | ETH, Base, HyperEVM | `0xD64089698f82cbCD91ba5e0422aDFa81D247eB62` |
| PendlePTAmortizedOracleV2 | All | `0x2185B40476510Ad27d17AF90889CE91BE9282A04` |
| PendlePTYieldSourceOracle | All | `0xc9Eda6330e1D1F7B91f72e459c85401D96BC48C9` |
| SpectraPTYieldSourceOracle | All | `0xF7DB5389ED49DfB3F260dB6e3389C7d28076E601` |
| StakingYieldSourceOracle | All | `0x985A6B8DDD9AacEA06ffbF3fc69DaEF48bC819ce` |
| SuperVaultYieldSourceOracle | All | `0xeEbb42210D8a8B165dCF154b325C588EE8dF149A` |
| YoYieldSourceOracle | All | `0x125d43f5F35c032a45aaD41EBE344d5c65D626D4` |

### Bridge Adapters

| Contract | Chains | Address |
|----------|--------|---------|
| AcrossV3Adapter | ETH | `0x4dC34c4Eb23973F3551526C2AFE8ffb7f70F0fD7` |
| AcrossV3Adapter | Base, Uni, World | `0x59d557E862E11c2Ac55Af11c4E0458f66bAb1BeA` |
| AcrossV3Adapter | BNB | `0x6DAfED46E7250A2653A5d4ed16F793d19B501ff7` |
| AcrossV3Adapter | Arb | `0x4858bD9a13EeEc482d440bF1FcAE2100D37AD315` |
| AcrossV3Adapter | OP | `0x946Df68ca1284D02cAe4F634d0f150E7fD88e29D` |
| AcrossV3Adapter | Poly | `0x8D58754A88bD1F1Ccf8dd22860d913e9933463e5` |
| AcrossV3Adapter | HyperEVM | `0x381D5EA470D13ceb51e5dFDd2A28a03b15d4F054` |
| DebridgeAdapter | All except Uni, World | `0x5bE003c2cD2DaCD4Cd23488DB7E74568475a36d8` |

### Hooks

> Hook addresses may vary across chains. Always verify hook addresses against the onchain registry before integrating directly.

| Hook | Chains | Address |
|------|--------|---------|
| AcrossSendFundsAndExecuteOnDstHook | ETH | `0x39962bE24192d0d6B6e3a19f332e3c825604d16A` |
| AcrossSendFundsAndExecuteOnDstHook | Base, Uni, World | `0xd724315eEebefe346985E028A7382158390cB892` |
| AcrossSendFundsAndExecuteOnDstHook | BNB | `0x03c551601e099C62812cBC3d5741ebECe1A58476` |
| AcrossSendFundsAndExecuteOnDstHook | Arb | `0x424d9552825aeE50b0bF34d2Bd8B6f3eEFA46A7f` |
| AcrossSendFundsAndExecuteOnDstHook | OP | `0x70c371683Cc5aB1eE60Da0aC3C7166E49BFf8336` |
| AcrossSendFundsAndExecuteOnDstHook | Poly | `0xc2FB04Dcd5d2dB4e6d4f67F48604fc554bADa60B` |
| AcrossSendFundsAndExecuteOnDstHook | HyperEVM | `0x95b43AbEEdd47FA9f74Ff3586900D79D3E43d282` |
| ApproveAndDeposit4626VaultHook | All | `0xF37535D96712FBaEf6D868e721E7b987ad1E6A86` |
| ApproveAndDeposit5115VaultHook | All | `0x44c7a40f05771FdAEAee61f36902D95cbf593988` |
| ApproveAndRequestDeposit7540VaultHook | All | `0x840B2b0553683dE46c5e6382D1a405f44773b43F` |
| ApproveAndSwapKyberSwapHook | All | `0xF3818ac90DCA76a7Efe40C3cB2548F96B2236595` |
| ApproveAndSwapOdosV2Hook | ETH | `0x067696e1EfBD25cAfD3B55648ED253C20A7d9671` |
| ApproveAndSwapOdosV2Hook | Base | `0x3E10d4105F826dFc8929845C94c019CDAF4d93cD` |
| ApproveAndSwapOdosV2Hook | BNB | `0xA47265CAF50a939dB95eB3237851d467265c20C3` |
| ApproveAndSwapOdosV2Hook | Arb | `0x5F3ECd5b9209F718470e42cE50778f64e563A7A7` |
| ApproveAndSwapOdosV2Hook | OP | `0xcCe79E3E4c7ADD7a25DfcAfe69d0d78991AcCB96` |
| ApproveAndSwapOdosV2Hook | Poly | `0x034208a8d1D204952db69376B2921A278C00204a` |
| ApproveAndSwapOdosV2Hook | Uni | `0xaE9E9C5f15C213b84a366581972425b790c11c2e` |
| ApproveAndSwapOdosV2Hook | Avax | `0x2D677F4F2fD22d8271c97D86fA17a580cBeBfe9C` |
| ApproveAndSwapOdosV2Hook | Sonic | `0xA357Dd134ccB087401f562be8158969D9e85104f` |
| ApproveAndSwapSparkPSMExactInHook | Base | `0x3e2E2948AB83CCF5024Dba60D362ee14Beb4346f` |
| ApproveAndSwapSparkPSMExactOutHook | Base | `0x9dd7b19c89F5FF980E962aCca76d09d02793c544` |
| ApproveAndSwapUniswapV3Hook | HyperEVM | `0xe1537482F70014fE10FAa988BA8e238CDae053E3` |
| ApproveERC20Hook | All | `0x8b789980dc6cC7d88E30C442D704646ff7F6d306` |
| BatchTransferFromHook | All | `0x816d5de8835FB7A003896f486fCce46a6DEBB00A` |
| BatchTransferHook | All | `0x55475fa30E3EEC5996e9eF32B483E30Ed288CcBC` |
| CancelDepositRequest7540Hook | All | `0x0BBA42ddaa6ef6CCd228BD6270565F87154E921A` |
| CancelRedeemRequest7540Hook | All | `0x542601AfAEeB2E5dFc7d1F2fEEF5911285f0c2c0` |
| CircleGatewayAddDelegateHook | All | `0xa7aE1263fd7D6017770147393CE130f16E1fE2cC` |
| CircleGatewayMinterHook | All | `0x659b720a5E8E08D2c379165D17bA5F74dd104824` |
| CircleGatewayRemoveDelegateHook | All | `0x00FbC4e3608A26E0d05905759C2A6188fDa0e2Cd` |
| CircleGatewayWalletHook | All | `0x6383d09cF761FeAa4108B65130793c7eDA356dB5` |
| ClaimCancelDepositRequest7540Hook | All | `0xdf958A047D90b202A7097b5f9B67Bb8CB5285858` |
| ClaimCancelRedeemRequest7540Hook | All | `0x0668f9a638f34928f0bD91588E7B157F0699D594` |
| DeBridgeCancelOrderHook | All except Uni, World | `0xc5DbbBe2D8B9ff884a7ed33f1352021CD2b482C9` |
| DeBridgeSendOrderAndExecuteOnDstHook | All except Uni, World | `0x162225095A384787a257bced9b8893b29C8f1795` |
| Deposit4626VaultHook | All | `0xa067037B29431C1ff23dEB9b10CC8a1669B0698E` |
| Deposit5115VaultHook | All | `0x32209A2302865784bC1Dc0bd3C55D0A6eB205851` |
| Deposit7540VaultHook | All | `0x0aB1b12E090775fA67DF6e1b44DFAEe676C1DC84` |
| EthenaCooldownSharesHook | All | `0x1bD7698cc3E3f4cCF5D6CBC74a611bdDEaB18aeF` |
| EthenaUnstakeHook | All | `0xaEBeEc6548B727fd4f3464B19D99f4676d7e7796` |
| MarkRootAsUsedHook | All | `0xE61774Aa87a05fB1B5665158F2b5E0E10C71B5e2` |
| MerklClaimRewardHook | All | `0x96a7939F94bcd57B031AAe01c1e187f3EBaCCa10` |
| OfframpTokensHook | All | `0x08BA6FF01e651B0c0A0D99AC66563097da2789f7` |
| PendleRouterRedeemHook | ETH, Base, BNB, Arb, OP, Bera, Sonic, HyperEVM | `0xAae2DB58E2f426b910f518cCbB627545aEdaff2F` |
| PendleRouterSwapHook | ETH, Base, BNB, Arb, OP, Bera, Sonic, HyperEVM | `0x02A0A95C379220E9759960A8Ee923cBbC2d305cd` |
| PendleUnifiedHook | ETH, Base, HyperEVM | `0xF2D6a1d41804BeB856a28218eFD260e51CA1aE87` |
| RecordPurchasePendlePTAmortizedOracleHook | ETH, Base | `0x771D4fF615F87eA00488a2dbcb70DF98BDA03FA3` |
| RecordPurchasePendlePTAmortizedOracleHookV2 | All | `0xA0E61eb90817E28aBbb5a40045921B69bb784431` |
| RecordRedemptionPendlePTAmortizedOracleHook | ETH, Base | `0xb68a34AF34E64a8b3bB72983088ACeB2fAE326Fc` |
| RecordRedemptionPendlePTAmortizedOracleHookV2 | All | `0x2A4F700923324B14bd546630Fe87B1ee08C89634` |
| Redeem4626VaultHook | All | `0x5c3edf3F7c43828Bb72a668e2B29f9e2D9Af5A69` |
| Redeem5115VaultHook | All | `0x6aB1fD107825F9bB3E079d23508A07486b44e6F5` |
| Redeem7540VaultHook | All | `0xE165FBBc89a60756F57Cf0E34c04c35Cc1BbA79D` |
| RequestDeposit7540VaultHook | All | `0xBE7738b26992a322D53edEb9a39331Bf11b60097` |
| RequestRedeem7540VaultHook | All | `0x9c21c130aCF3EADd781AE79d75FF5fC4Bd216797` |
| SetOperator7540Hook | All | `0x86f9DcE0a1A83C501Ba95a1aB1088d67978636A8` |
| SetSlippageHook | All | `0x6551d0140FFdB28920E5e84DC3DA31f4bfe4364E` |
| Swap1InchHook | All except Bera, World, HyperEVM | `0x1303d5f3e3D9e4a81945cB0C2e309E1940d2425C` |
| SwapKyberSwapHook | All | `0x1851A7fa26B507b681187585e3B368B95FbfdBB0` |
| SwapOdosV2Hook | ETH | `0x98313d15797048F60B1bFd41AE7A2B9877056079` |
| SwapOdosV2Hook | Base | `0x074F9973EBfB050D7abc75a5cB03491d675DA843` |
| SwapOdosV2Hook | BNB | `0x6AADDD4047E7e9723c3446eb2E538cE88C12A12c` |
| SwapOdosV2Hook | Arb | `0xCCB88A83190257681BC0925e933A19c7Ca0b6d94` |
| SwapOdosV2Hook | OP | `0xF65319b5D299a3B0c29cfAC7579b27845d3461E4` |
| SwapOdosV2Hook | Poly | `0x36B84691d3375fDEC79cA5b3142d0bc908e016cC` |
| SwapOdosV2Hook | Uni | `0xaB587deCE4E2D5F39bEC2922ED745A97BD2F2a8E` |
| SwapOdosV2Hook | Avax | `0x6B9308Ca3bAF94aC3516Df08e0cd83ed1D7c312d` |
| SwapOdosV2Hook | Sonic | `0xF3162BEf5c8f0564a0F7DbC88119BbA453DA58B9` |
| SwapSparkPSMExactInHook | Base | `0x9B8cc0D7DecF5B90481eA761670b1abB334450Ae` |
| SwapSparkPSMExactOutHook | Base | `0x5D6FFbE88Ffb41BD8252727a461d121692890870` |
| SwapUniswapV3Hook | HyperEVM | `0x5c6FA6540b49C14dDc003f11E043fe2020cF5e76` |
| TransferERC20Hook | All | `0x6031c3953BC12D9Af4651B7ed517190A31a67ca4` |
| TransferHook | All | `0x0d54e1b4060bBD598eE6ec8F7A587fF1789164E9` |

## SuperVault Contracts

| Contract | Chains | Address |
|----------|--------|---------|
| ECDSAPPSOracle | ETH, Base, HyperEVM | `0x366d88F03B8EF34eb49F32a927ff6e1609F694F2` |
| SuperBank | ETH, Base, HyperEVM | `0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15` |
| SuperformGasOracle | Base, HyperEVM | `0x473b88f017dE39d85a102DA01A35a1b3507eBcFc` |
| SuperGovernor | ETH, Base, HyperEVM | `0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4` |
| SuperVault | ETH, Base, HyperEVM | `0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2` |
| SuperVaultAggregator | ETH, Base, HyperEVM | `0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698` |
| SuperVaultBatchOperator | ETH, Base, HyperEVM | `0x3047601ea12565C65b715137799a458971BA070B` |
| SuperVaultEscrow | ETH, Base, HyperEVM | `0x8982cf48eaB6616f2892888410afad9b0CD2BC9B` |
| SuperVaultStrategy | ETH, Base, HyperEVM | `0x770abd170404B8ed8182c04f380E567e647b457D` |

Individual vault, strategy, and escrow addresses vary per curator. To look up a specific SuperVault's contracts, visit the Curator App.

## $UP Token

| Token | Chains | Address |
|-------|--------|---------|
| $UP | ETH | `0x1d926bbe67425c9f507b9a0e8030eedc7880bf33` |
| $UP (LayerZero OFT) | Base | `0x5b2193fdc451c1f847be09ca9d13a4bf60f8c86b` |
| $UP (LayerZero OFT) | HyperEVM | `0x642fFC3496AcA19106BAB7A42F1F221a329654fe` |
| sUP (staking vault) | Base | `0x2c71f70e2Ec720AE061Ae7E0316fC9654d94f417` |
| UpOFTAdapter | ETH | `0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD` |
