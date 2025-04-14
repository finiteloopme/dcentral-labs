package chain

import (
	"fmt"
	"io"
	"math/big"
	"reflect"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/apache/beam/sdks/v2/go/pkg/beam/core/graph/coder"
	"github.com/ethereum/go-ethereum/common"
)

// DecodedEvent holds the structured data after ABI decoding.
// Fields correspond to parameters across all monitored events.
// Use pointers for optional fields (fields not present in all events).
type DecodedEvent struct {
	// Common across multiple events
	Amount      *big.Int `json:"amount,omitempty"`
	ProjectId   *big.Int `json:"projectId,omitempty"`   // Note: Assuming ProjectCreatedEvent.ProjectId was typo 'epoch'
	EpochNumber *big.Int `json:"epochNumber,omitempty"` // Used in RewardClaim* events

	// FundsAddedEvent
	Funder string `json:"funder,omitempty"`

	// FundsWithdrawnEvent / ProjectRewardsRecipientUpdatedEvent
	Recipient string `json:"recipient,omitempty"`

	// InitializedEvent
	Version *big.Int `json:"version,omitempty"`

	// InvalidRewardClaimAmountEvent
	RequestEpochNumber *big.Int `json:"requestEpochNumber,omitempty"`
	DiffAmmount        *big.Int `json:"diffAmmount,omitempty"`

	// ProjectAddedEvent / ProjectOwnerUpdatedEvent
	Owner string `json:"owner,omitempty"`

	// ProjectAddedEvent
	RewardsRecipient string   `json:"rewardsRecipient,omitempty"`
	MetadataUri      string   `json:"metadataUri,omitempty"` // Also used in ProjectMetadataUriUpdatedEvent
	ActiveFromEpoch  *big.Int `json:"activeFromEpoch,omitempty"`
	Contracts        []string `json:"contracts,omitempty"` // Slice of addresses

	// ProjectContractAddedEvent / ProjectContractRemovedEvent
	ContractAddress string `json:"contractAddress,omitempty"`

	// ProjectEnabledEvent
	EnabledOnEpochNumber *big.Int `json:"enabledOnEpochNumber,omitempty"`

	// ProjectSuspendedEvent
	SuspendedOnEpochNumber *big.Int `json:"suspendedOnEpochNumber,omitempty"`

	// RewardClaimConfirmationsLimitUpdatedEvent / RewardClaimEpochsLimitUpdatedEvent
	Limit *big.Int `json:"limit,omitempty"`

	// RoleAdminChangedEvent
	Role              string `json:"role,omitempty"` // Also used in RoleGrantedEvent, RoleRevokedEvent
	PreviousAdminRole string `json:"previousAdminRole,omitempty"`
	NewAdminRole      string `json:"newAdminRole,omitempty"`

	// RoleGrantedEvent / RoleRevokedEvent
	Account string `json:"account,omitempty"`
	Sender  string `json:"sender,omitempty"`

	// SfcAddressUpdatedEvent
	SfcAddress string `json:"sfcAddress,omitempty"`

	// UpgradedEvent
	Implementation string `json:"implementation,omitempty"`

	// SfcFeeUpdatedEvent
	Fee *big.Int `json:"fee,omitempty"`

	// --- Metadata ---
	Log       string `json:"log"`       // The raw log entry
	EventName string `json:"eventName"` // Name of the decoded event
}

type EthAddressType struct {
	*common.Address
}

var (
	addressType           = reflect.TypeOf((*EthAddressType)(nil)).Elem()
	ethAddressStorageType = reflect.TypeOf((*addressStorage)(nil)).Elem()
	// typeHash    = reflect.TypeOf((*common.Hash)(nil)).Elem()
)

type addressStorage struct {
	Address string `beam:"address"`
}

type AddressProvider struct{}

func (p *AddressProvider) FromLogicalType(rt reflect.Type) (reflect.Type, error) {
	if rt != addressType {
		return nil, fmt.Errorf("unable to provide schema.LogicalType for type %v, want %v", rt, addressType)
	}
	return ethAddressStorageType, nil
}
func (p *AddressProvider) BuildEncoder(rt reflect.Type) (func(any, io.Writer) error, error) {
	if _, err := p.FromLogicalType(rt); err != nil {
		return nil, err
	}
	enc, err := coder.RowEncoderForStruct(ethAddressStorageType)
	if err != nil {
		return nil, err
	}
	return func(iface any, w io.Writer) error {
		v := iface.(common.Address)
		return enc(addressStorage{
			Address: v.String(),
		}, w)
	}, nil
}

// BuildDecoder builds a Beam schema decoder for the TimestampNanos type.
func (p *AddressProvider) BuildDecoder(rt reflect.Type) (func(io.Reader) (any, error), error) {
	if _, err := p.FromLogicalType(rt); err != nil {
		return nil, err
	}
	dec, err := coder.RowDecoderForStruct(ethAddressStorageType)
	if err != nil {
		return nil, err
	}
	return func(r io.Reader) (any, error) {
		s, err := dec(r)
		if err != nil {
			return nil, err
		}
		tn := s.(addressStorage)

		return common.BytesToAddress([]byte(tn.Address)), nil
	}, nil
}

// Helper functions are no longer strictly needed here as conversion happens
// during JSON marshalling or attribute creation, but keep if useful elsewhere.

func init() {
	// Register custom types
	beam.RegisterType(reflect.TypeOf((*DecodedEvent)(nil)).Elem())
	beam.RegisterType(reflect.TypeOf((*big.Int)(nil)))
	// beam.RegisterType(reflect.TypeOf((*common.Address)(nil)).Elem())
	// beam.RegisterType(reflect.TypeOf((*common.Hash)(nil)).Elem())
	//beam.RegisterSchemaProvider(addressType, &AddressProvider{})
}
