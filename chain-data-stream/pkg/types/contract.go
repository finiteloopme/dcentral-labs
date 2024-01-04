package types

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

type SwapDescription struct {
	SrcToken         common.Address
	DstToken         common.Address
	SrcReceiver      common.Address
	DstReceiver      common.Address
	Amount           *big.Int
	MinReturnAmount  *big.Int
	GuaranteedAmount *big.Int
	Flags            *big.Int
	Referrer         common.Address
	Permit           []byte
}

type CallDescription struct {
	TargetWithMandatory *big.Int
	GasLimit            *big.Int
	Value               *big.Int
	Data                []byte
}

type SwapFunction struct {
	Caller common.Address
	Desc   SwapDescription
	Calls  []CallDescription
}
