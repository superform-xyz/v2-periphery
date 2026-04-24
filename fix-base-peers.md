# Set Base OFT Peers for HyperEVM and Flare

## Summary

The Base UpOFT (`0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B`) is missing peers for HyperEVM and Flare. ETH peer is already set.

## Transaction 1: Set HyperEVM Peer

**To:** `0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B` (Base UpOFT)

**Value:** 0

**Calldata:**
```
0x3400288b000000000000000000000000000000000000000000000000000000000000769f000000000000000000000000642ffc3496aca19106bab7a42f1f221a329654fe
```

**Decoded:**
- **Function:** `setPeer(uint32,bytes32)`
- **EID:** `30367` (HyperEVM)
- **Peer:** `0x000000000000000000000000642fFC3496AcA19106BAB7A42F1F221a329654fe` (HyperEVM OFT)

## Transaction 2: Set Flare Peer

**To:** `0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B` (Base UpOFT)

**Value:** 0

**Calldata:**
```
0x3400288b0000000000000000000000000000000000000000000000000000000000007657000000000000000000000000e030a89fd2b7f858c8aa47725679ca25d467dfd1
```

**Decoded:**
- **Function:** `setPeer(uint32,bytes32)`
- **EID:** `30295` (Flare)
- **Peer:** `0x000000000000000000000000e030A89fd2b7f858c8aA47725679CA25D467dFD1` (Flare OFT)

## Verification

After execution, verify with:
```
cast call 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B "peers(uint32)(bytes32)" 30367 --rpc-url <BASE_RPC>
cast call 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B "peers(uint32)(bytes32)" 30295 --rpc-url <BASE_RPC>
```

Expected:
- `30367` → `0x000000000000000000000000642ffc3496aca19106bab7a42f1f221a329654fe`
- `30295` → `0x000000000000000000000000e030a89fd2b7f858c8aa47725679ca25d467dfd1`
