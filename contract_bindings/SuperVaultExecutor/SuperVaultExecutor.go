// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package supervaultexecutor

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// ISuperVaultStrategyExecuteArgs is an auto generated low-level Go binding around an user-defined struct.
type ISuperVaultStrategyExecuteArgs struct {
	Hooks                     []common.Address
	HookCalldata              [][]byte
	ExpectedAssetsOrSharesOut []*big.Int
	GlobalProofs              [][][32]byte
	StrategyProofs            [][][32]byte
}

// SuperVaultExecutorMetaData contains all meta data concerning the SuperVaultExecutor contract.
var SuperVaultExecutorMetaData = &bind.MetaData{
	ABI: "[{\"type\":\"constructor\",\"inputs\":[{\"name\":\"superGovernor_\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"admin_\",\"type\":\"address\",\"internalType\":\"address\"}],\"stateMutability\":\"nonpayable\"},{\"type\":\"receive\",\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"DEFAULT_ADMIN_ROLE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"MAX_BATCH_SIZE\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_GOVERNOR\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"address\",\"internalType\":\"contractISuperGovernor\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"SUPER_VAULT_AGGREGATOR_KEY\",\"inputs\":[],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"executeHooks\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"args\",\"type\":\"tuple\",\"internalType\":\"structISuperVaultStrategy.ExecuteArgs\",\"components\":[{\"name\":\"hooks\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"hookCalldata\",\"type\":\"bytes[]\",\"internalType\":\"bytes[]\"},{\"name\":\"expectedAssetsOrSharesOut\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"},{\"name\":\"globalProofs\",\"type\":\"bytes32[][]\",\"internalType\":\"bytes32[][]\"},{\"name\":\"strategyProofs\",\"type\":\"bytes32[][]\",\"internalType\":\"bytes32[][]\"}]}],\"outputs\":[],\"stateMutability\":\"payable\"},{\"type\":\"function\",\"name\":\"fulfillCancelRedeemRequests\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controllers\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"fulfillRedeemRequests\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"controllers\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"totalAssetsOut\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"getRoleAdmin\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getSessionKeyData\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"},{\"name\":\"grantedByManager\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"generation\",\"type\":\"uint96\",\"internalType\":\"uint96\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"getStrategyGeneration\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"uint96\",\"internalType\":\"uint96\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"grantRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"grantSessionKey\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"internalType\":\"uint256\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"grantSessionKeysBatch\",\"inputs\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"sessionKeys\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"expiries\",\"type\":\"uint256[]\",\"internalType\":\"uint256[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"hasRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"invalidateAllSessionKeys\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"isSessionKeyValid\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"pauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"renounceRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"callerConfirmation\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeRole\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeSessionKey\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"revokeSessionKeysBatch\",\"inputs\":[{\"name\":\"strategies\",\"type\":\"address[]\",\"internalType\":\"address[]\"},{\"name\":\"sessionKeys\",\"type\":\"address[]\",\"internalType\":\"address[]\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"skimPerformanceFee\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"supportsInterface\",\"inputs\":[{\"name\":\"interfaceId\",\"type\":\"bytes4\",\"internalType\":\"bytes4\"}],\"outputs\":[{\"name\":\"\",\"type\":\"bool\",\"internalType\":\"bool\"}],\"stateMutability\":\"view\"},{\"type\":\"function\",\"name\":\"sweepETH\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"function\",\"name\":\"unpauseStrategy\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"internalType\":\"address\"}],\"outputs\":[],\"stateMutability\":\"nonpayable\"},{\"type\":\"event\",\"name\":\"AllSessionKeysInvalidated\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"newGeneration\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ETHRefunded\",\"inputs\":[{\"name\":\"recipient\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"ETHSwept\",\"inputs\":[{\"name\":\"to\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleAdminChanged\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"previousAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"newAdminRole\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleGranted\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"RoleRevoked\",\"inputs\":[{\"name\":\"role\",\"type\":\"bytes32\",\"indexed\":true,\"internalType\":\"bytes32\"},{\"name\":\"account\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sender\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SessionKeyGranted\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"expiry\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"},{\"name\":\"grantedByManager\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"generation\",\"type\":\"uint256\",\"indexed\":false,\"internalType\":\"uint256\"}],\"anonymous\":false},{\"type\":\"event\",\"name\":\"SessionKeyRevoked\",\"inputs\":[{\"name\":\"strategy\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"},{\"name\":\"sessionKey\",\"type\":\"address\",\"indexed\":true,\"internalType\":\"address\"}],\"anonymous\":false},{\"type\":\"error\",\"name\":\"ARRAY_LENGTH_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlBadConfirmation\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"AccessControlUnauthorizedAccount\",\"inputs\":[{\"name\":\"account\",\"type\":\"address\",\"internalType\":\"address\"},{\"name\":\"neededRole\",\"type\":\"bytes32\",\"internalType\":\"bytes32\"}]},{\"type\":\"error\",\"name\":\"BATCH_SIZE_EXCEEDED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"CALLER_NOT_PRIMARY_MANAGER\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EMPTY_ARRAY\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ETH_TRANSFER_FAILED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"EXPIRY_IN_PAST\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"PRIMARY_MANAGER_CHANGED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ReentrancyGuardReentrantCall\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SESSION_KEY_EXPIRED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SESSION_KEY_GENERATION_MISMATCH\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"SESSION_KEY_NOT_AUTHORIZED\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_ADDRESS\",\"inputs\":[]},{\"type\":\"error\",\"name\":\"ZERO_EXPIRY\",\"inputs\":[]}]",
	Bin: "0x60c060405234801561000f575f5ffd5b50604051611de4380380611de483398101604081905261002e916101b2565b600180556001600160a01b038216158061004f57506001600160a01b038116155b1561006d5760405163538ba4f960e01b815260040160405180910390fd5b6001600160a01b03821660808190526040805163c983881960e01b8152905163c9838819916004808201926020929091908290030181865afa1580156100b5573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906100d991906101e3565b60a0526100e65f826100ee565b5050506101fa565b5f828152602081815260408083206001600160a01b038516845290915281205460ff1661018e575f838152602081815260408083206001600160a01b03861684529091529020805460ff191660011790556101463390565b6001600160a01b0316826001600160a01b0316847f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a4506001610191565b505f5b92915050565b80516001600160a01b03811681146101ad575f5ffd5b919050565b5f5f604083850312156101c3575f5ffd5b6101cc83610197565b91506101da60208401610197565b90509250929050565b5f602082840312156101f3575f5ffd5b5051919050565b60805160a051611bbb6102295f395f81816104990152610e7101525f81816102bf0152610e990152611bbb5ff3fe608060405260043610610164575f3560e01c8063560ea6d6116100cd578063bca0cc2d11610087578063d3f6b59811610062578063d3f6b598146104ee578063d547741f1461050d578063e2aab9f01461052c578063fcea42971461054b575f5ffd5b8063bca0cc2d14610488578063c5321d4b146104bb578063cfdbf254146104da575f5ffd5b8063560ea6d6146103a45780635d9f8be7146103c357806381e9c8d1146103e257806391d1485414610401578063a217fddf14610420578063abbf720914610433575f5ffd5b80632638a2931161011e5780632638a2931461025d5780632f2ff15d1461027057806336568abe1461028f57806339c7d246146102ae5780634802254e146102f95780634bdc6ebd14610385575f5ffd5b806301ffc9a71461016f5780630ff323a3146101a35780631163b2b0146101c457806314ea652d146101e35780631f09178214610202578063248a9ca314610221575f5ffd5b3661016b57005b5f5ffd5b34801561017a575f5ffd5b5061018e610189366004611480565b61056a565b60405190151581526020015b60405180910390f35b3480156101ae575f5ffd5b506101c26101bd3660046114c2565b6105a0565b005b3480156101cf575f5ffd5b506101c26101de3660046114c2565b610621565b3480156101ee575f5ffd5b506101c26101fd366004611525565b6106dc565b34801561020d575f5ffd5b506101c261021c366004611591565b6107ec565b34801561022c575f5ffd5b5061024f61023b3660046115c8565b5f9081526020819052604090206001015490565b60405190815260200161019a565b6101c261026b3660046115df565b610803565b34801561027b575f5ffd5b506101c261028a366004611627565b6108fc565b34801561029a575f5ffd5b506101c26102a9366004611627565b610926565b3480156102b9575f5ffd5b506102e17f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200161019a565b348015610304575f5ffd5b50610359610313366004611591565b6001600160a01b039182165f9081526002602090815260408083209385168352929052208054600190910154909291811691600160a01b9091046001600160601b031690565b604080519384526001600160a01b0390921660208401526001600160601b03169082015260600161019a565b348015610390575f5ffd5b506101c261039f36600461164a565b61095e565b3480156103af575f5ffd5b506101c26103be36600461169b565b6109d3565b3480156103ce575f5ffd5b506101c26103dd3660046116d9565b6109e7565b3480156103ed575f5ffd5b5061018e6103fc366004611591565b610a67565b34801561040c575f5ffd5b5061018e61041b366004611627565b610b6d565b34801561042b575f5ffd5b5061024f5f81565b34801561043e575f5ffd5b5061047061044d3660046114c2565b6001600160a01b03165f908152600360205260409020546001600160601b031690565b6040516001600160601b03909116815260200161019a565b348015610493575f5ffd5b5061024f7f000000000000000000000000000000000000000000000000000000000000000081565b3480156104c6575f5ffd5b506101c26104d536600461175b565b610b95565b3480156104e5575f5ffd5b5061024f603281565b3480156104f9575f5ffd5b506101c26105083660046114c2565b610cb2565b348015610518575f5ffd5b506101c2610527366004611627565b610cfd565b348015610537575f5ffd5b506101c26105463660046114c2565b610d21565b348015610556575f5ffd5b506101c26105653660046114c2565b610d89565b5f6001600160e01b03198216637965db0b60e01b148061059a57506301ffc9a760e01b6001600160e01b03198316145b92915050565b6105a8610e38565b5f6105b1610e62565b90506105bd8282610f0f565b604051630ff323a360e01b81526001600160a01b038381166004830152821690630ff323a3906024015b5f604051808303815f87803b1580156105fe575f5ffd5b505af1158015610610573d5f5f3e3d5ffd5b505050505061061e60018055565b50565b610629610e38565b5f61063381611057565b6001600160a01b03821661065a5760405163538ba4f960e01b815260040160405180910390fd5b4780156106d1575f5f5f5f5f858861c350f190508061068c57604051634c67134d60e11b815260040160405180910390fd5b836001600160a01b03167fab31ddb82a9ca2de51c9befe9da7c6e815e12eac49ae58b8d9cb6b7a181cbc71836040516106c791815260200190565b60405180910390a2505b505061061e60018055565b825f8190036106fe57604051630339e54160e61b815260040160405180910390fd5b6032811115610720576040516368ddd13760e11b815260040160405180910390fd5b80821461074057604051634456f5e960e11b815260040160405180910390fd5b5f610749610e62565b90505f5b828110156107e35761078587878381811061076a5761076a6117fa565b905060200201602081019061077f91906114c2565b83611061565b6107db87878381811061079a5761079a6117fa565b90506020020160208101906107af91906114c2565b8686848181106107c1576107c16117fa565b90506020020160208101906107d691906114c2565b6110ec565b60010161074d565b50505050505050565b6107f58261118c565b6107ff82826110ec565b5050565b61080b610e38565b61081482611221565b5f61081f3447611822565b9050826001600160a01b0316632f82b89a34846040518363ffffffff1660e01b815260040161084e91906119bc565b5f604051808303818588803b158015610865575f5ffd5b505af1158015610877573d5f5f3e3d5ffd5b50505050505f81476108899190611822565b905080156108f1575f5f5f5f5f85335af19050806108ba57604051634c67134d60e11b815260040160405180910390fd5b60405182815233907fb593fb7f0ed454d644104a0e41134bbe1f73b78eb6c1c6dc7f82a46ef25ea7859060200160405180910390a2505b50506107ff60018055565b5f8281526020819052604090206001015461091681611057565b6109208383611232565b50505050565b6001600160a01b038116331461094f5760405163334bd91960e11b815260040160405180910390fd5b61095982826112c1565b505050565b610966610e38565b61096f83611221565b604051635523cd2d60e01b81526001600160a01b03841690635523cd2d9061099d9085908590600401611b06565b5f604051808303815f87803b1580156109b4575f5ffd5b505af11580156109c6573d5f5f3e3d5ffd5b5050505061095960018055565b6109dc8361118c565b61095983838361132a565b6109ef610e38565b6109f885611221565b6040516348785dc360e01b81526001600160a01b038616906348785dc390610a2a908790879087908790600401611b19565b5f604051808303815f87803b158015610a41575f5ffd5b505af1158015610a53573d5f5f3e3d5ffd5b50505050610a6060018055565b5050505050565b6001600160a01b038083165f908152600260209081526040808320938516835292905290812080541580610a9b5750805442115b15610aa9575f91505061059a565b6001600160a01b0384165f908152600360205260409020546001820154600160a01b90046001600160601b03908116911614610ae8575f91505061059a565b610af0610e62565b60018201546040516375c8d4d960e11b81526001600160a01b039182166004820152868216602482015291169063eb91a9b290604401602060405180830381865afa158015610b41573d5f5f3e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610b659190611b4a565b949350505050565b5f918252602082815260408084206001600160a01b0393909316845291905290205460ff1690565b845f819003610bb757604051630339e54160e61b815260040160405180910390fd5b6032811115610bd9576040516368ddd13760e11b815260040160405180910390fd5b8084141580610be85750808214155b15610c0657604051634456f5e960e11b815260040160405180910390fd5b5f610c0f610e62565b90505f5b82811015610ca757610c3089898381811061076a5761076a6117fa565b610c9f898983818110610c4557610c456117fa565b9050602002016020810190610c5a91906114c2565b888884818110610c6c57610c6c6117fa565b9050602002016020810190610c8191906114c2565b878785818110610c9357610c936117fa565b9050602002013561132a565b600101610c13565b505050505050505050565b610cba610e38565b5f610cc3610e62565b9050610ccf8282610f0f565b604051631a7ed6b360e31b81526001600160a01b03838116600483015282169063d3f6b598906024016105e7565b5f82815260208190526040902060010154610d1781611057565b61092083836112c1565b610d29610e38565b610d3281611221565b806001600160a01b031663772ecfb76040518163ffffffff1660e01b81526004015f604051808303815f87803b158015610d6a575f5ffd5b505af1158015610d7c573d5f5f3e3d5ffd5b5050505061061e60018055565b610d928161118c565b6001600160a01b0381165f90815260036020526040812080548290610dbf906001600160601b0316611b69565b91906101000a8154816001600160601b0302191690836001600160601b0316021790559050816001600160a01b03167fe5eeca603c4108df725bc074154afd8c6100bb89d579de2af5b1c825dd7ea43f82604051610e2c91906001600160601b0391909116815260200190565b60405180910390a25050565b600260015403610e5b57604051633ee5aeb560e01b815260040160405180910390fd5b6002600155565b6040516321f8a72160e01b81527f000000000000000000000000000000000000000000000000000000000000000060048201525f907f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316906321f8a72190602401602060405180830381865afa158015610ee6573d5f5f3e3d5ffd5b505050506040513d601f19601f82011682018060405250810190610f0a9190611b93565b905090565b6001600160a01b0382165f90815260026020908152604080832033845290915281208054909103610f5357604051639841d32560e01b815260040160405180910390fd5b8054421115610f755760405163d21917ab60e01b815260040160405180910390fd5b6001600160a01b0383165f908152600360205260409020546001820154600160a01b90046001600160601b03908116911614610fc4576040516348f54b1b60e11b815260040160405180910390fd5b60018101546040516375c8d4d960e11b81526001600160a01b03918216600482015284821660248201529083169063eb91a9b290604401602060405180830381865afa158015611016573d5f5f3e3d5ffd5b505050506040513d601f19601f8201168201806040525081019061103a9190611b4a565b6109595760405163f3e37ca160e01b815260040160405180910390fd5b61061e8133611443565b6040516375c8d4d960e11b81523360048201526001600160a01b03838116602483015282169063eb91a9b290604401602060405180830381865afa1580156110ab573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906110cf9190611b4a565b6107ff5760405163846c9dcd60e01b815260040160405180910390fd5b6001600160a01b038083165f908152600260209081526040808320938516835292905290812054900361113257604051639841d32560e01b815260040160405180910390fd5b6001600160a01b038083165f81815260026020908152604080832094861680845294909152808220828155600101829055517f744157ccffbd293a2e8644928cd7d23d650f869b88f72d7bfea8041b76ca6bec9190a35050565b611194610e62565b6040516375c8d4d960e11b81523360048201526001600160a01b038381166024830152919091169063eb91a9b290604401602060405180830381865afa1580156111e0573d5f5f3e3d5ffd5b505050506040513d601f19601f820116820180604052508101906112049190611b4a565b61061e5760405163846c9dcd60e01b815260040160405180910390fd5b61061e8161122d610e62565b610f0f565b5f61123d8383610b6d565b6112ba575f838152602081815260408083206001600160a01b03861684529091529020805460ff191660011790556112723390565b6001600160a01b0316826001600160a01b0316847f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a450600161059a565b505f61059a565b5f6112cc8383610b6d565b156112ba575f838152602081815260408083206001600160a01b0386168085529252808320805460ff1916905551339286917ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b9190a450600161059a565b6001600160a01b0382166113515760405163538ba4f960e01b815260040160405180910390fd5b805f03611371576040516357f9962360e11b815260040160405180910390fd5b4281116113915760405163ca5d75dd60e01b815260040160405180910390fd5b6001600160a01b038381165f818152600360209081526040808320548151606081018352878152338185018181526001600160601b03938416838601818152898952600288528689208d8c16808b52908952988790209451855591519151909416600160a01b0298169790971760019091015581518781529283018190529493917f4a430ced6af766c588afffa2deaee6bcff879596cddaf7261e12fbeeee1abb1e910160405180910390a450505050565b61144d8282610b6d565b6107ff5760405163e2517d3f60e01b81526001600160a01b03821660048201526024810183905260440160405180910390fd5b5f60208284031215611490575f5ffd5b81356001600160e01b0319811681146114a7575f5ffd5b9392505050565b6001600160a01b038116811461061e575f5ffd5b5f602082840312156114d2575f5ffd5b81356114a7816114ae565b5f5f83601f8401126114ed575f5ffd5b50813567ffffffffffffffff811115611504575f5ffd5b6020830191508360208260051b850101111561151e575f5ffd5b9250929050565b5f5f5f5f60408587031215611538575f5ffd5b843567ffffffffffffffff81111561154e575f5ffd5b61155a878288016114dd565b909550935050602085013567ffffffffffffffff811115611579575f5ffd5b611585878288016114dd565b95989497509550505050565b5f5f604083850312156115a2575f5ffd5b82356115ad816114ae565b915060208301356115bd816114ae565b809150509250929050565b5f602082840312156115d8575f5ffd5b5035919050565b5f5f604083850312156115f0575f5ffd5b82356115fb816114ae565b9150602083013567ffffffffffffffff811115611616575f5ffd5b830160a081860312156115bd575f5ffd5b5f5f60408385031215611638575f5ffd5b8235915060208301356115bd816114ae565b5f5f5f6040848603121561165c575f5ffd5b8335611667816114ae565b9250602084013567ffffffffffffffff811115611682575f5ffd5b61168e868287016114dd565b9497909650939450505050565b5f5f5f606084860312156116ad575f5ffd5b83356116b8816114ae565b925060208401356116c8816114ae565b929592945050506040919091013590565b5f5f5f5f5f606086880312156116ed575f5ffd5b85356116f8816114ae565b9450602086013567ffffffffffffffff811115611713575f5ffd5b61171f888289016114dd565b909550935050604086013567ffffffffffffffff81111561173e575f5ffd5b61174a888289016114dd565b969995985093965092949392505050565b5f5f5f5f5f5f60608789031215611770575f5ffd5b863567ffffffffffffffff811115611786575f5ffd5b61179289828a016114dd565b909750955050602087013567ffffffffffffffff8111156117b1575f5ffd5b6117bd89828a016114dd565b909550935050604087013567ffffffffffffffff8111156117dc575f5ffd5b6117e889828a016114dd565b979a9699509497509295939492505050565b634e487b7160e01b5f52603260045260245ffd5b634e487b7160e01b5f52601160045260245ffd5b8181038181111561059a5761059a61180e565b5f5f8335601e1984360301811261184a575f5ffd5b830160208101925035905067ffffffffffffffff811115611869575f5ffd5b8060051b360382131561151e575f5ffd5b81835281816020850137505f828201602090810191909152601f909101601f19169091010190565b5f8383855260208501945060208460051b820101835f5b8681101561192b57838303601f19018852813536879003601e190181126118de575f5ffd5b860160208101903567ffffffffffffffff8111156118fa575f5ffd5b803603821315611908575f5ffd5b61191385828461187a565b60209a8b019a909550939093019250506001016118b9565b50909695505050505050565b8183525f6001600160fb1b0383111561194e575f5ffd5b8260051b80836020870137939093016020019392505050565b5f8383855260208501945060208460051b820101835f5b8681101561192b57838303601f190188526119998287611835565b6119a4858284611937565b60209a8b019a9095509390930192505060010161197e565b602081525f60c082016119cf8485611835565b60a0602086015291829052905f9060e085015b81831015611a135783356119f5816114ae565b6001600160a01b0316815260209384019360019390930192016119e2565b611a206020880188611835565b878303601f1901604089015294509250611a3b8185856118a2565b9350505050611a4d6040850185611835565b848303601f19016060860152611a64838284611937565b92505050611a756060850185611835565b848303601f19016080860152611a8c838284611967565b92505050611a9d6080850185611835565b848303601f190160a0860152611ab4838284611967565b9695505050505050565b8183526020830192505f815f5b84811015611afc578135611ade816114ae565b6001600160a01b031686526020958601959190910190600101611acb565b5093949350505050565b602081525f610b65602083018486611abe565b604081525f611b2c604083018688611abe565b8281036020840152611b3f818587611937565b979650505050505050565b5f60208284031215611b5a575f5ffd5b815180151581146114a7575f5ffd5b5f6001600160601b0382166001600160601b038103611b8a57611b8a61180e565b60010192915050565b5f60208284031215611ba3575f5ffd5b81516114a7816114ae56fea164736f6c634300081e000a",
}

// SuperVaultExecutorABI is the input ABI used to generate the binding from.
// Deprecated: Use SuperVaultExecutorMetaData.ABI instead.
var SuperVaultExecutorABI = SuperVaultExecutorMetaData.ABI

// SuperVaultExecutorBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use SuperVaultExecutorMetaData.Bin instead.
var SuperVaultExecutorBin = SuperVaultExecutorMetaData.Bin

// DeploySuperVaultExecutor deploys a new Ethereum contract, binding an instance of SuperVaultExecutor to it.
func DeploySuperVaultExecutor(auth *bind.TransactOpts, backend bind.ContractBackend, superGovernor_ common.Address, admin_ common.Address) (common.Address, *types.Transaction, *SuperVaultExecutor, error) {
	parsed, err := SuperVaultExecutorMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(SuperVaultExecutorBin), backend, superGovernor_, admin_)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &SuperVaultExecutor{SuperVaultExecutorCaller: SuperVaultExecutorCaller{contract: contract}, SuperVaultExecutorTransactor: SuperVaultExecutorTransactor{contract: contract}, SuperVaultExecutorFilterer: SuperVaultExecutorFilterer{contract: contract}}, nil
}

// SuperVaultExecutor is an auto generated Go binding around an Ethereum contract.
type SuperVaultExecutor struct {
	SuperVaultExecutorCaller     // Read-only binding to the contract
	SuperVaultExecutorTransactor // Write-only binding to the contract
	SuperVaultExecutorFilterer   // Log filterer for contract events
}

// SuperVaultExecutorCaller is an auto generated read-only Go binding around an Ethereum contract.
type SuperVaultExecutorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultExecutorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type SuperVaultExecutorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultExecutorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type SuperVaultExecutorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// SuperVaultExecutorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type SuperVaultExecutorSession struct {
	Contract     *SuperVaultExecutor // Generic contract binding to set the session for
	CallOpts     bind.CallOpts       // Call options to use throughout this session
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// SuperVaultExecutorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type SuperVaultExecutorCallerSession struct {
	Contract *SuperVaultExecutorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts             // Call options to use throughout this session
}

// SuperVaultExecutorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type SuperVaultExecutorTransactorSession struct {
	Contract     *SuperVaultExecutorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts             // Transaction auth options to use throughout this session
}

// SuperVaultExecutorRaw is an auto generated low-level Go binding around an Ethereum contract.
type SuperVaultExecutorRaw struct {
	Contract *SuperVaultExecutor // Generic contract binding to access the raw methods on
}

// SuperVaultExecutorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type SuperVaultExecutorCallerRaw struct {
	Contract *SuperVaultExecutorCaller // Generic read-only contract binding to access the raw methods on
}

// SuperVaultExecutorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type SuperVaultExecutorTransactorRaw struct {
	Contract *SuperVaultExecutorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewSuperVaultExecutor creates a new instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutor(address common.Address, backend bind.ContractBackend) (*SuperVaultExecutor, error) {
	contract, err := bindSuperVaultExecutor(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutor{SuperVaultExecutorCaller: SuperVaultExecutorCaller{contract: contract}, SuperVaultExecutorTransactor: SuperVaultExecutorTransactor{contract: contract}, SuperVaultExecutorFilterer: SuperVaultExecutorFilterer{contract: contract}}, nil
}

// NewSuperVaultExecutorCaller creates a new read-only instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutorCaller(address common.Address, caller bind.ContractCaller) (*SuperVaultExecutorCaller, error) {
	contract, err := bindSuperVaultExecutor(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorCaller{contract: contract}, nil
}

// NewSuperVaultExecutorTransactor creates a new write-only instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutorTransactor(address common.Address, transactor bind.ContractTransactor) (*SuperVaultExecutorTransactor, error) {
	contract, err := bindSuperVaultExecutor(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorTransactor{contract: contract}, nil
}

// NewSuperVaultExecutorFilterer creates a new log filterer instance of SuperVaultExecutor, bound to a specific deployed contract.
func NewSuperVaultExecutorFilterer(address common.Address, filterer bind.ContractFilterer) (*SuperVaultExecutorFilterer, error) {
	contract, err := bindSuperVaultExecutor(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorFilterer{contract: contract}, nil
}

// bindSuperVaultExecutor binds a generic wrapper to an already deployed contract.
func bindSuperVaultExecutor(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := SuperVaultExecutorMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultExecutor *SuperVaultExecutorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultExecutor.Contract.SuperVaultExecutorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultExecutor *SuperVaultExecutorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SuperVaultExecutorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultExecutor *SuperVaultExecutorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SuperVaultExecutorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_SuperVaultExecutor *SuperVaultExecutorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _SuperVaultExecutor.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_SuperVaultExecutor *SuperVaultExecutorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_SuperVaultExecutor *SuperVaultExecutorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.contract.Transact(opts, method, params...)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) DEFAULTADMINROLE(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "DEFAULT_ADMIN_ROLE")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.DEFAULTADMINROLE(&_SuperVaultExecutor.CallOpts)
}

// DEFAULTADMINROLE is a free data retrieval call binding the contract method 0xa217fddf.
//
// Solidity: function DEFAULT_ADMIN_ROLE() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) DEFAULTADMINROLE() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.DEFAULTADMINROLE(&_SuperVaultExecutor.CallOpts)
}

// MAXBATCHSIZE is a free data retrieval call binding the contract method 0xcfdbf254.
//
// Solidity: function MAX_BATCH_SIZE() view returns(uint256)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) MAXBATCHSIZE(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "MAX_BATCH_SIZE")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// MAXBATCHSIZE is a free data retrieval call binding the contract method 0xcfdbf254.
//
// Solidity: function MAX_BATCH_SIZE() view returns(uint256)
func (_SuperVaultExecutor *SuperVaultExecutorSession) MAXBATCHSIZE() (*big.Int, error) {
	return _SuperVaultExecutor.Contract.MAXBATCHSIZE(&_SuperVaultExecutor.CallOpts)
}

// MAXBATCHSIZE is a free data retrieval call binding the contract method 0xcfdbf254.
//
// Solidity: function MAX_BATCH_SIZE() view returns(uint256)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) MAXBATCHSIZE() (*big.Int, error) {
	return _SuperVaultExecutor.Contract.MAXBATCHSIZE(&_SuperVaultExecutor.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) SUPERGOVERNOR(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "SUPER_GOVERNOR")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultExecutor *SuperVaultExecutorSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultExecutor.Contract.SUPERGOVERNOR(&_SuperVaultExecutor.CallOpts)
}

// SUPERGOVERNOR is a free data retrieval call binding the contract method 0x39c7d246.
//
// Solidity: function SUPER_GOVERNOR() view returns(address)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) SUPERGOVERNOR() (common.Address, error) {
	return _SuperVaultExecutor.Contract.SUPERGOVERNOR(&_SuperVaultExecutor.CallOpts)
}

// SUPERVAULTAGGREGATORKEY is a free data retrieval call binding the contract method 0xbca0cc2d.
//
// Solidity: function SUPER_VAULT_AGGREGATOR_KEY() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) SUPERVAULTAGGREGATORKEY(opts *bind.CallOpts) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "SUPER_VAULT_AGGREGATOR_KEY")

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// SUPERVAULTAGGREGATORKEY is a free data retrieval call binding the contract method 0xbca0cc2d.
//
// Solidity: function SUPER_VAULT_AGGREGATOR_KEY() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorSession) SUPERVAULTAGGREGATORKEY() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.SUPERVAULTAGGREGATORKEY(&_SuperVaultExecutor.CallOpts)
}

// SUPERVAULTAGGREGATORKEY is a free data retrieval call binding the contract method 0xbca0cc2d.
//
// Solidity: function SUPER_VAULT_AGGREGATOR_KEY() view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) SUPERVAULTAGGREGATORKEY() ([32]byte, error) {
	return _SuperVaultExecutor.Contract.SUPERVAULTAGGREGATORKEY(&_SuperVaultExecutor.CallOpts)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) GetRoleAdmin(opts *bind.CallOpts, role [32]byte) ([32]byte, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "getRoleAdmin", role)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperVaultExecutor.Contract.GetRoleAdmin(&_SuperVaultExecutor.CallOpts, role)
}

// GetRoleAdmin is a free data retrieval call binding the contract method 0x248a9ca3.
//
// Solidity: function getRoleAdmin(bytes32 role) view returns(bytes32)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) GetRoleAdmin(role [32]byte) ([32]byte, error) {
	return _SuperVaultExecutor.Contract.GetRoleAdmin(&_SuperVaultExecutor.CallOpts, role)
}

// GetSessionKeyData is a free data retrieval call binding the contract method 0x4802254e.
//
// Solidity: function getSessionKeyData(address strategy, address sessionKey) view returns(uint256 expiry, address grantedByManager, uint96 generation)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) GetSessionKeyData(opts *bind.CallOpts, strategy common.Address, sessionKey common.Address) (struct {
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
}, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "getSessionKeyData", strategy, sessionKey)

	outstruct := new(struct {
		Expiry           *big.Int
		GrantedByManager common.Address
		Generation       *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Expiry = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.GrantedByManager = *abi.ConvertType(out[1], new(common.Address)).(*common.Address)
	outstruct.Generation = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// GetSessionKeyData is a free data retrieval call binding the contract method 0x4802254e.
//
// Solidity: function getSessionKeyData(address strategy, address sessionKey) view returns(uint256 expiry, address grantedByManager, uint96 generation)
func (_SuperVaultExecutor *SuperVaultExecutorSession) GetSessionKeyData(strategy common.Address, sessionKey common.Address) (struct {
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
}, error) {
	return _SuperVaultExecutor.Contract.GetSessionKeyData(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// GetSessionKeyData is a free data retrieval call binding the contract method 0x4802254e.
//
// Solidity: function getSessionKeyData(address strategy, address sessionKey) view returns(uint256 expiry, address grantedByManager, uint96 generation)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) GetSessionKeyData(strategy common.Address, sessionKey common.Address) (struct {
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
}, error) {
	return _SuperVaultExecutor.Contract.GetSessionKeyData(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// GetStrategyGeneration is a free data retrieval call binding the contract method 0xabbf7209.
//
// Solidity: function getStrategyGeneration(address strategy) view returns(uint96)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) GetStrategyGeneration(opts *bind.CallOpts, strategy common.Address) (*big.Int, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "getStrategyGeneration", strategy)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetStrategyGeneration is a free data retrieval call binding the contract method 0xabbf7209.
//
// Solidity: function getStrategyGeneration(address strategy) view returns(uint96)
func (_SuperVaultExecutor *SuperVaultExecutorSession) GetStrategyGeneration(strategy common.Address) (*big.Int, error) {
	return _SuperVaultExecutor.Contract.GetStrategyGeneration(&_SuperVaultExecutor.CallOpts, strategy)
}

// GetStrategyGeneration is a free data retrieval call binding the contract method 0xabbf7209.
//
// Solidity: function getStrategyGeneration(address strategy) view returns(uint96)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) GetStrategyGeneration(strategy common.Address) (*big.Int, error) {
	return _SuperVaultExecutor.Contract.GetStrategyGeneration(&_SuperVaultExecutor.CallOpts, strategy)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) HasRole(opts *bind.CallOpts, role [32]byte, account common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "hasRole", role, account)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.HasRole(&_SuperVaultExecutor.CallOpts, role, account)
}

// HasRole is a free data retrieval call binding the contract method 0x91d14854.
//
// Solidity: function hasRole(bytes32 role, address account) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) HasRole(role [32]byte, account common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.HasRole(&_SuperVaultExecutor.CallOpts, role, account)
}

// IsSessionKeyValid is a free data retrieval call binding the contract method 0x81e9c8d1.
//
// Solidity: function isSessionKeyValid(address strategy, address sessionKey) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) IsSessionKeyValid(opts *bind.CallOpts, strategy common.Address, sessionKey common.Address) (bool, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "isSessionKeyValid", strategy, sessionKey)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsSessionKeyValid is a free data retrieval call binding the contract method 0x81e9c8d1.
//
// Solidity: function isSessionKeyValid(address strategy, address sessionKey) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorSession) IsSessionKeyValid(strategy common.Address, sessionKey common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.IsSessionKeyValid(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// IsSessionKeyValid is a free data retrieval call binding the contract method 0x81e9c8d1.
//
// Solidity: function isSessionKeyValid(address strategy, address sessionKey) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) IsSessionKeyValid(strategy common.Address, sessionKey common.Address) (bool, error) {
	return _SuperVaultExecutor.Contract.IsSessionKeyValid(&_SuperVaultExecutor.CallOpts, strategy, sessionKey)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _SuperVaultExecutor.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVaultExecutor.Contract.SupportsInterface(&_SuperVaultExecutor.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_SuperVaultExecutor *SuperVaultExecutorCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _SuperVaultExecutor.Contract.SupportsInterface(&_SuperVaultExecutor.CallOpts, interfaceId)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2638a293.
//
// Solidity: function executeHooks(address strategy, (address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) ExecuteHooks(opts *bind.TransactOpts, strategy common.Address, args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "executeHooks", strategy, args)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2638a293.
//
// Solidity: function executeHooks(address strategy, (address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) ExecuteHooks(strategy common.Address, args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.ExecuteHooks(&_SuperVaultExecutor.TransactOpts, strategy, args)
}

// ExecuteHooks is a paid mutator transaction binding the contract method 0x2638a293.
//
// Solidity: function executeHooks(address strategy, (address[],bytes[],uint256[],bytes32[][],bytes32[][]) args) payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) ExecuteHooks(strategy common.Address, args ISuperVaultStrategyExecuteArgs) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.ExecuteHooks(&_SuperVaultExecutor.TransactOpts, strategy, args)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x4bdc6ebd.
//
// Solidity: function fulfillCancelRedeemRequests(address strategy, address[] controllers) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) FulfillCancelRedeemRequests(opts *bind.TransactOpts, strategy common.Address, controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "fulfillCancelRedeemRequests", strategy, controllers)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x4bdc6ebd.
//
// Solidity: function fulfillCancelRedeemRequests(address strategy, address[] controllers) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) FulfillCancelRedeemRequests(strategy common.Address, controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillCancelRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers)
}

// FulfillCancelRedeemRequests is a paid mutator transaction binding the contract method 0x4bdc6ebd.
//
// Solidity: function fulfillCancelRedeemRequests(address strategy, address[] controllers) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) FulfillCancelRedeemRequests(strategy common.Address, controllers []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillCancelRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x5d9f8be7.
//
// Solidity: function fulfillRedeemRequests(address strategy, address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) FulfillRedeemRequests(opts *bind.TransactOpts, strategy common.Address, controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "fulfillRedeemRequests", strategy, controllers, totalAssetsOut)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x5d9f8be7.
//
// Solidity: function fulfillRedeemRequests(address strategy, address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) FulfillRedeemRequests(strategy common.Address, controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers, totalAssetsOut)
}

// FulfillRedeemRequests is a paid mutator transaction binding the contract method 0x5d9f8be7.
//
// Solidity: function fulfillRedeemRequests(address strategy, address[] controllers, uint256[] totalAssetsOut) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) FulfillRedeemRequests(strategy common.Address, controllers []common.Address, totalAssetsOut []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.FulfillRedeemRequests(&_SuperVaultExecutor.TransactOpts, strategy, controllers, totalAssetsOut)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) GrantRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "grantRole", role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// GrantRole is a paid mutator transaction binding the contract method 0x2f2ff15d.
//
// Solidity: function grantRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) GrantRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// GrantSessionKey is a paid mutator transaction binding the contract method 0x560ea6d6.
//
// Solidity: function grantSessionKey(address strategy, address sessionKey, uint256 expiry) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) GrantSessionKey(opts *bind.TransactOpts, strategy common.Address, sessionKey common.Address, expiry *big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "grantSessionKey", strategy, sessionKey, expiry)
}

// GrantSessionKey is a paid mutator transaction binding the contract method 0x560ea6d6.
//
// Solidity: function grantSessionKey(address strategy, address sessionKey, uint256 expiry) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) GrantSessionKey(strategy common.Address, sessionKey common.Address, expiry *big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey, expiry)
}

// GrantSessionKey is a paid mutator transaction binding the contract method 0x560ea6d6.
//
// Solidity: function grantSessionKey(address strategy, address sessionKey, uint256 expiry) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) GrantSessionKey(strategy common.Address, sessionKey common.Address, expiry *big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey, expiry)
}

// GrantSessionKeysBatch is a paid mutator transaction binding the contract method 0xc5321d4b.
//
// Solidity: function grantSessionKeysBatch(address[] strategies, address[] sessionKeys, uint256[] expiries) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) GrantSessionKeysBatch(opts *bind.TransactOpts, strategies []common.Address, sessionKeys []common.Address, expiries []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "grantSessionKeysBatch", strategies, sessionKeys, expiries)
}

// GrantSessionKeysBatch is a paid mutator transaction binding the contract method 0xc5321d4b.
//
// Solidity: function grantSessionKeysBatch(address[] strategies, address[] sessionKeys, uint256[] expiries) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) GrantSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address, expiries []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys, expiries)
}

// GrantSessionKeysBatch is a paid mutator transaction binding the contract method 0xc5321d4b.
//
// Solidity: function grantSessionKeysBatch(address[] strategies, address[] sessionKeys, uint256[] expiries) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) GrantSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address, expiries []*big.Int) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.GrantSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys, expiries)
}

// InvalidateAllSessionKeys is a paid mutator transaction binding the contract method 0xfcea4297.
//
// Solidity: function invalidateAllSessionKeys(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) InvalidateAllSessionKeys(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "invalidateAllSessionKeys", strategy)
}

// InvalidateAllSessionKeys is a paid mutator transaction binding the contract method 0xfcea4297.
//
// Solidity: function invalidateAllSessionKeys(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) InvalidateAllSessionKeys(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.InvalidateAllSessionKeys(&_SuperVaultExecutor.TransactOpts, strategy)
}

// InvalidateAllSessionKeys is a paid mutator transaction binding the contract method 0xfcea4297.
//
// Solidity: function invalidateAllSessionKeys(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) InvalidateAllSessionKeys(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.InvalidateAllSessionKeys(&_SuperVaultExecutor.TransactOpts, strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) PauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "pauseStrategy", strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.PauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// PauseStrategy is a paid mutator transaction binding the contract method 0xd3f6b598.
//
// Solidity: function pauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) PauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.PauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RenounceRole(opts *bind.TransactOpts, role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "renounceRole", role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RenounceRole(&_SuperVaultExecutor.TransactOpts, role, callerConfirmation)
}

// RenounceRole is a paid mutator transaction binding the contract method 0x36568abe.
//
// Solidity: function renounceRole(bytes32 role, address callerConfirmation) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RenounceRole(role [32]byte, callerConfirmation common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RenounceRole(&_SuperVaultExecutor.TransactOpts, role, callerConfirmation)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RevokeRole(opts *bind.TransactOpts, role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "revokeRole", role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// RevokeRole is a paid mutator transaction binding the contract method 0xd547741f.
//
// Solidity: function revokeRole(bytes32 role, address account) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RevokeRole(role [32]byte, account common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeRole(&_SuperVaultExecutor.TransactOpts, role, account)
}

// RevokeSessionKey is a paid mutator transaction binding the contract method 0x1f091782.
//
// Solidity: function revokeSessionKey(address strategy, address sessionKey) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RevokeSessionKey(opts *bind.TransactOpts, strategy common.Address, sessionKey common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "revokeSessionKey", strategy, sessionKey)
}

// RevokeSessionKey is a paid mutator transaction binding the contract method 0x1f091782.
//
// Solidity: function revokeSessionKey(address strategy, address sessionKey) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RevokeSessionKey(strategy common.Address, sessionKey common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey)
}

// RevokeSessionKey is a paid mutator transaction binding the contract method 0x1f091782.
//
// Solidity: function revokeSessionKey(address strategy, address sessionKey) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RevokeSessionKey(strategy common.Address, sessionKey common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKey(&_SuperVaultExecutor.TransactOpts, strategy, sessionKey)
}

// RevokeSessionKeysBatch is a paid mutator transaction binding the contract method 0x14ea652d.
//
// Solidity: function revokeSessionKeysBatch(address[] strategies, address[] sessionKeys) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) RevokeSessionKeysBatch(opts *bind.TransactOpts, strategies []common.Address, sessionKeys []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "revokeSessionKeysBatch", strategies, sessionKeys)
}

// RevokeSessionKeysBatch is a paid mutator transaction binding the contract method 0x14ea652d.
//
// Solidity: function revokeSessionKeysBatch(address[] strategies, address[] sessionKeys) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) RevokeSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys)
}

// RevokeSessionKeysBatch is a paid mutator transaction binding the contract method 0x14ea652d.
//
// Solidity: function revokeSessionKeysBatch(address[] strategies, address[] sessionKeys) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) RevokeSessionKeysBatch(strategies []common.Address, sessionKeys []common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.RevokeSessionKeysBatch(&_SuperVaultExecutor.TransactOpts, strategies, sessionKeys)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0xe2aab9f0.
//
// Solidity: function skimPerformanceFee(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) SkimPerformanceFee(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "skimPerformanceFee", strategy)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0xe2aab9f0.
//
// Solidity: function skimPerformanceFee(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) SkimPerformanceFee(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SkimPerformanceFee(&_SuperVaultExecutor.TransactOpts, strategy)
}

// SkimPerformanceFee is a paid mutator transaction binding the contract method 0xe2aab9f0.
//
// Solidity: function skimPerformanceFee(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) SkimPerformanceFee(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SkimPerformanceFee(&_SuperVaultExecutor.TransactOpts, strategy)
}

// SweepETH is a paid mutator transaction binding the contract method 0x1163b2b0.
//
// Solidity: function sweepETH(address to) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) SweepETH(opts *bind.TransactOpts, to common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "sweepETH", to)
}

// SweepETH is a paid mutator transaction binding the contract method 0x1163b2b0.
//
// Solidity: function sweepETH(address to) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) SweepETH(to common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SweepETH(&_SuperVaultExecutor.TransactOpts, to)
}

// SweepETH is a paid mutator transaction binding the contract method 0x1163b2b0.
//
// Solidity: function sweepETH(address to) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) SweepETH(to common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.SweepETH(&_SuperVaultExecutor.TransactOpts, to)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) UnpauseStrategy(opts *bind.TransactOpts, strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.Transact(opts, "unpauseStrategy", strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.UnpauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// UnpauseStrategy is a paid mutator transaction binding the contract method 0x0ff323a3.
//
// Solidity: function unpauseStrategy(address strategy) returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) UnpauseStrategy(strategy common.Address) (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.UnpauseStrategy(&_SuperVaultExecutor.TransactOpts, strategy)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactor) Receive(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _SuperVaultExecutor.contract.RawTransact(opts, nil) // calldata is disallowed for receive function
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorSession) Receive() (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.Receive(&_SuperVaultExecutor.TransactOpts)
}

// Receive is a paid mutator transaction binding the contract receive function.
//
// Solidity: receive() payable returns()
func (_SuperVaultExecutor *SuperVaultExecutorTransactorSession) Receive() (*types.Transaction, error) {
	return _SuperVaultExecutor.Contract.Receive(&_SuperVaultExecutor.TransactOpts)
}

// SuperVaultExecutorAllSessionKeysInvalidatedIterator is returned from FilterAllSessionKeysInvalidated and is used to iterate over the raw logs and unpacked data for AllSessionKeysInvalidated events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorAllSessionKeysInvalidatedIterator struct {
	Event *SuperVaultExecutorAllSessionKeysInvalidated // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorAllSessionKeysInvalidatedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorAllSessionKeysInvalidated)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorAllSessionKeysInvalidated)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorAllSessionKeysInvalidatedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorAllSessionKeysInvalidatedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorAllSessionKeysInvalidated represents a AllSessionKeysInvalidated event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorAllSessionKeysInvalidated struct {
	Strategy      common.Address
	NewGeneration *big.Int
	Raw           types.Log // Blockchain specific contextual infos
}

// FilterAllSessionKeysInvalidated is a free log retrieval operation binding the contract event 0xe5eeca603c4108df725bc074154afd8c6100bb89d579de2af5b1c825dd7ea43f.
//
// Solidity: event AllSessionKeysInvalidated(address indexed strategy, uint256 newGeneration)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterAllSessionKeysInvalidated(opts *bind.FilterOpts, strategy []common.Address) (*SuperVaultExecutorAllSessionKeysInvalidatedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "AllSessionKeysInvalidated", strategyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorAllSessionKeysInvalidatedIterator{contract: _SuperVaultExecutor.contract, event: "AllSessionKeysInvalidated", logs: logs, sub: sub}, nil
}

// WatchAllSessionKeysInvalidated is a free log subscription operation binding the contract event 0xe5eeca603c4108df725bc074154afd8c6100bb89d579de2af5b1c825dd7ea43f.
//
// Solidity: event AllSessionKeysInvalidated(address indexed strategy, uint256 newGeneration)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchAllSessionKeysInvalidated(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorAllSessionKeysInvalidated, strategy []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "AllSessionKeysInvalidated", strategyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorAllSessionKeysInvalidated)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "AllSessionKeysInvalidated", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseAllSessionKeysInvalidated is a log parse operation binding the contract event 0xe5eeca603c4108df725bc074154afd8c6100bb89d579de2af5b1c825dd7ea43f.
//
// Solidity: event AllSessionKeysInvalidated(address indexed strategy, uint256 newGeneration)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseAllSessionKeysInvalidated(log types.Log) (*SuperVaultExecutorAllSessionKeysInvalidated, error) {
	event := new(SuperVaultExecutorAllSessionKeysInvalidated)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "AllSessionKeysInvalidated", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorETHRefundedIterator is returned from FilterETHRefunded and is used to iterate over the raw logs and unpacked data for ETHRefunded events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHRefundedIterator struct {
	Event *SuperVaultExecutorETHRefunded // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorETHRefundedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorETHRefunded)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorETHRefunded)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorETHRefundedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorETHRefundedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorETHRefunded represents a ETHRefunded event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHRefunded struct {
	Recipient common.Address
	Amount    *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterETHRefunded is a free log retrieval operation binding the contract event 0xb593fb7f0ed454d644104a0e41134bbe1f73b78eb6c1c6dc7f82a46ef25ea785.
//
// Solidity: event ETHRefunded(address indexed recipient, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterETHRefunded(opts *bind.FilterOpts, recipient []common.Address) (*SuperVaultExecutorETHRefundedIterator, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "ETHRefunded", recipientRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorETHRefundedIterator{contract: _SuperVaultExecutor.contract, event: "ETHRefunded", logs: logs, sub: sub}, nil
}

// WatchETHRefunded is a free log subscription operation binding the contract event 0xb593fb7f0ed454d644104a0e41134bbe1f73b78eb6c1c6dc7f82a46ef25ea785.
//
// Solidity: event ETHRefunded(address indexed recipient, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchETHRefunded(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorETHRefunded, recipient []common.Address) (event.Subscription, error) {

	var recipientRule []interface{}
	for _, recipientItem := range recipient {
		recipientRule = append(recipientRule, recipientItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "ETHRefunded", recipientRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorETHRefunded)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHRefunded", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseETHRefunded is a log parse operation binding the contract event 0xb593fb7f0ed454d644104a0e41134bbe1f73b78eb6c1c6dc7f82a46ef25ea785.
//
// Solidity: event ETHRefunded(address indexed recipient, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseETHRefunded(log types.Log) (*SuperVaultExecutorETHRefunded, error) {
	event := new(SuperVaultExecutorETHRefunded)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHRefunded", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorETHSweptIterator is returned from FilterETHSwept and is used to iterate over the raw logs and unpacked data for ETHSwept events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHSweptIterator struct {
	Event *SuperVaultExecutorETHSwept // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorETHSweptIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorETHSwept)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorETHSwept)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorETHSweptIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorETHSweptIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorETHSwept represents a ETHSwept event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorETHSwept struct {
	To     common.Address
	Amount *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterETHSwept is a free log retrieval operation binding the contract event 0xab31ddb82a9ca2de51c9befe9da7c6e815e12eac49ae58b8d9cb6b7a181cbc71.
//
// Solidity: event ETHSwept(address indexed to, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterETHSwept(opts *bind.FilterOpts, to []common.Address) (*SuperVaultExecutorETHSweptIterator, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "ETHSwept", toRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorETHSweptIterator{contract: _SuperVaultExecutor.contract, event: "ETHSwept", logs: logs, sub: sub}, nil
}

// WatchETHSwept is a free log subscription operation binding the contract event 0xab31ddb82a9ca2de51c9befe9da7c6e815e12eac49ae58b8d9cb6b7a181cbc71.
//
// Solidity: event ETHSwept(address indexed to, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchETHSwept(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorETHSwept, to []common.Address) (event.Subscription, error) {

	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "ETHSwept", toRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorETHSwept)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHSwept", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseETHSwept is a log parse operation binding the contract event 0xab31ddb82a9ca2de51c9befe9da7c6e815e12eac49ae58b8d9cb6b7a181cbc71.
//
// Solidity: event ETHSwept(address indexed to, uint256 amount)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseETHSwept(log types.Log) (*SuperVaultExecutorETHSwept, error) {
	event := new(SuperVaultExecutorETHSwept)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "ETHSwept", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorRoleAdminChangedIterator is returned from FilterRoleAdminChanged and is used to iterate over the raw logs and unpacked data for RoleAdminChanged events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleAdminChangedIterator struct {
	Event *SuperVaultExecutorRoleAdminChanged // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorRoleAdminChangedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorRoleAdminChanged)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorRoleAdminChanged)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorRoleAdminChangedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorRoleAdminChangedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorRoleAdminChanged represents a RoleAdminChanged event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleAdminChanged struct {
	Role              [32]byte
	PreviousAdminRole [32]byte
	NewAdminRole      [32]byte
	Raw               types.Log // Blockchain specific contextual infos
}

// FilterRoleAdminChanged is a free log retrieval operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterRoleAdminChanged(opts *bind.FilterOpts, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (*SuperVaultExecutorRoleAdminChangedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorRoleAdminChangedIterator{contract: _SuperVaultExecutor.contract, event: "RoleAdminChanged", logs: logs, sub: sub}, nil
}

// WatchRoleAdminChanged is a free log subscription operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchRoleAdminChanged(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorRoleAdminChanged, role [][32]byte, previousAdminRole [][32]byte, newAdminRole [][32]byte) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var previousAdminRoleRule []interface{}
	for _, previousAdminRoleItem := range previousAdminRole {
		previousAdminRoleRule = append(previousAdminRoleRule, previousAdminRoleItem)
	}
	var newAdminRoleRule []interface{}
	for _, newAdminRoleItem := range newAdminRole {
		newAdminRoleRule = append(newAdminRoleRule, newAdminRoleItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "RoleAdminChanged", roleRule, previousAdminRoleRule, newAdminRoleRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorRoleAdminChanged)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleAdminChanged is a log parse operation binding the contract event 0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff.
//
// Solidity: event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseRoleAdminChanged(log types.Log) (*SuperVaultExecutorRoleAdminChanged, error) {
	event := new(SuperVaultExecutorRoleAdminChanged)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleAdminChanged", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorRoleGrantedIterator is returned from FilterRoleGranted and is used to iterate over the raw logs and unpacked data for RoleGranted events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleGrantedIterator struct {
	Event *SuperVaultExecutorRoleGranted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorRoleGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorRoleGranted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorRoleGranted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorRoleGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorRoleGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorRoleGranted represents a RoleGranted event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleGranted struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleGranted is a free log retrieval operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterRoleGranted(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperVaultExecutorRoleGrantedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorRoleGrantedIterator{contract: _SuperVaultExecutor.contract, event: "RoleGranted", logs: logs, sub: sub}, nil
}

// WatchRoleGranted is a free log subscription operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchRoleGranted(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorRoleGranted, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "RoleGranted", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorRoleGranted)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleGranted is a log parse operation binding the contract event 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d.
//
// Solidity: event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseRoleGranted(log types.Log) (*SuperVaultExecutorRoleGranted, error) {
	event := new(SuperVaultExecutorRoleGranted)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorRoleRevokedIterator is returned from FilterRoleRevoked and is used to iterate over the raw logs and unpacked data for RoleRevoked events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleRevokedIterator struct {
	Event *SuperVaultExecutorRoleRevoked // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorRoleRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorRoleRevoked)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorRoleRevoked)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorRoleRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorRoleRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorRoleRevoked represents a RoleRevoked event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorRoleRevoked struct {
	Role    [32]byte
	Account common.Address
	Sender  common.Address
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterRoleRevoked is a free log retrieval operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterRoleRevoked(opts *bind.FilterOpts, role [][32]byte, account []common.Address, sender []common.Address) (*SuperVaultExecutorRoleRevokedIterator, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorRoleRevokedIterator{contract: _SuperVaultExecutor.contract, event: "RoleRevoked", logs: logs, sub: sub}, nil
}

// WatchRoleRevoked is a free log subscription operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchRoleRevoked(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorRoleRevoked, role [][32]byte, account []common.Address, sender []common.Address) (event.Subscription, error) {

	var roleRule []interface{}
	for _, roleItem := range role {
		roleRule = append(roleRule, roleItem)
	}
	var accountRule []interface{}
	for _, accountItem := range account {
		accountRule = append(accountRule, accountItem)
	}
	var senderRule []interface{}
	for _, senderItem := range sender {
		senderRule = append(senderRule, senderItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "RoleRevoked", roleRule, accountRule, senderRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorRoleRevoked)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseRoleRevoked is a log parse operation binding the contract event 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b.
//
// Solidity: event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseRoleRevoked(log types.Log) (*SuperVaultExecutorRoleRevoked, error) {
	event := new(SuperVaultExecutorRoleRevoked)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "RoleRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorSessionKeyGrantedIterator is returned from FilterSessionKeyGranted and is used to iterate over the raw logs and unpacked data for SessionKeyGranted events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyGrantedIterator struct {
	Event *SuperVaultExecutorSessionKeyGranted // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorSessionKeyGrantedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorSessionKeyGranted)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorSessionKeyGranted)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorSessionKeyGrantedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorSessionKeyGrantedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorSessionKeyGranted represents a SessionKeyGranted event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyGranted struct {
	Strategy         common.Address
	SessionKey       common.Address
	Expiry           *big.Int
	GrantedByManager common.Address
	Generation       *big.Int
	Raw              types.Log // Blockchain specific contextual infos
}

// FilterSessionKeyGranted is a free log retrieval operation binding the contract event 0x4a430ced6af766c588afffa2deaee6bcff879596cddaf7261e12fbeeee1abb1e.
//
// Solidity: event SessionKeyGranted(address indexed strategy, address indexed sessionKey, uint256 expiry, address indexed grantedByManager, uint256 generation)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterSessionKeyGranted(opts *bind.FilterOpts, strategy []common.Address, sessionKey []common.Address, grantedByManager []common.Address) (*SuperVaultExecutorSessionKeyGrantedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	var grantedByManagerRule []interface{}
	for _, grantedByManagerItem := range grantedByManager {
		grantedByManagerRule = append(grantedByManagerRule, grantedByManagerItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "SessionKeyGranted", strategyRule, sessionKeyRule, grantedByManagerRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorSessionKeyGrantedIterator{contract: _SuperVaultExecutor.contract, event: "SessionKeyGranted", logs: logs, sub: sub}, nil
}

// WatchSessionKeyGranted is a free log subscription operation binding the contract event 0x4a430ced6af766c588afffa2deaee6bcff879596cddaf7261e12fbeeee1abb1e.
//
// Solidity: event SessionKeyGranted(address indexed strategy, address indexed sessionKey, uint256 expiry, address indexed grantedByManager, uint256 generation)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchSessionKeyGranted(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorSessionKeyGranted, strategy []common.Address, sessionKey []common.Address, grantedByManager []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	var grantedByManagerRule []interface{}
	for _, grantedByManagerItem := range grantedByManager {
		grantedByManagerRule = append(grantedByManagerRule, grantedByManagerItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "SessionKeyGranted", strategyRule, sessionKeyRule, grantedByManagerRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorSessionKeyGranted)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyGranted", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseSessionKeyGranted is a log parse operation binding the contract event 0x4a430ced6af766c588afffa2deaee6bcff879596cddaf7261e12fbeeee1abb1e.
//
// Solidity: event SessionKeyGranted(address indexed strategy, address indexed sessionKey, uint256 expiry, address indexed grantedByManager, uint256 generation)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseSessionKeyGranted(log types.Log) (*SuperVaultExecutorSessionKeyGranted, error) {
	event := new(SuperVaultExecutorSessionKeyGranted)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyGranted", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// SuperVaultExecutorSessionKeyRevokedIterator is returned from FilterSessionKeyRevoked and is used to iterate over the raw logs and unpacked data for SessionKeyRevoked events raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyRevokedIterator struct {
	Event *SuperVaultExecutorSessionKeyRevoked // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *SuperVaultExecutorSessionKeyRevokedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(SuperVaultExecutorSessionKeyRevoked)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(SuperVaultExecutorSessionKeyRevoked)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *SuperVaultExecutorSessionKeyRevokedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *SuperVaultExecutorSessionKeyRevokedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// SuperVaultExecutorSessionKeyRevoked represents a SessionKeyRevoked event raised by the SuperVaultExecutor contract.
type SuperVaultExecutorSessionKeyRevoked struct {
	Strategy   common.Address
	SessionKey common.Address
	Raw        types.Log // Blockchain specific contextual infos
}

// FilterSessionKeyRevoked is a free log retrieval operation binding the contract event 0x744157ccffbd293a2e8644928cd7d23d650f869b88f72d7bfea8041b76ca6bec.
//
// Solidity: event SessionKeyRevoked(address indexed strategy, address indexed sessionKey)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) FilterSessionKeyRevoked(opts *bind.FilterOpts, strategy []common.Address, sessionKey []common.Address) (*SuperVaultExecutorSessionKeyRevokedIterator, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.FilterLogs(opts, "SessionKeyRevoked", strategyRule, sessionKeyRule)
	if err != nil {
		return nil, err
	}
	return &SuperVaultExecutorSessionKeyRevokedIterator{contract: _SuperVaultExecutor.contract, event: "SessionKeyRevoked", logs: logs, sub: sub}, nil
}

// WatchSessionKeyRevoked is a free log subscription operation binding the contract event 0x744157ccffbd293a2e8644928cd7d23d650f869b88f72d7bfea8041b76ca6bec.
//
// Solidity: event SessionKeyRevoked(address indexed strategy, address indexed sessionKey)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) WatchSessionKeyRevoked(opts *bind.WatchOpts, sink chan<- *SuperVaultExecutorSessionKeyRevoked, strategy []common.Address, sessionKey []common.Address) (event.Subscription, error) {

	var strategyRule []interface{}
	for _, strategyItem := range strategy {
		strategyRule = append(strategyRule, strategyItem)
	}
	var sessionKeyRule []interface{}
	for _, sessionKeyItem := range sessionKey {
		sessionKeyRule = append(sessionKeyRule, sessionKeyItem)
	}

	logs, sub, err := _SuperVaultExecutor.contract.WatchLogs(opts, "SessionKeyRevoked", strategyRule, sessionKeyRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(SuperVaultExecutorSessionKeyRevoked)
				if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyRevoked", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseSessionKeyRevoked is a log parse operation binding the contract event 0x744157ccffbd293a2e8644928cd7d23d650f869b88f72d7bfea8041b76ca6bec.
//
// Solidity: event SessionKeyRevoked(address indexed strategy, address indexed sessionKey)
func (_SuperVaultExecutor *SuperVaultExecutorFilterer) ParseSessionKeyRevoked(log types.Log) (*SuperVaultExecutorSessionKeyRevoked, error) {
	event := new(SuperVaultExecutorSessionKeyRevoked)
	if err := _SuperVaultExecutor.contract.UnpackLog(event, "SessionKeyRevoked", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
