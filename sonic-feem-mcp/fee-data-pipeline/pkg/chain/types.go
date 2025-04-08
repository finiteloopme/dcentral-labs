package chain

import (
	"math/big"
	"reflect"

	"github.com/apache/beam/sdks/v2/go/pkg/beam"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
)

// DecodedEvent holds the structured data after ABI decoding.
// Customize this based on the events in your ABI.
// DecodedEvent holds the structured data after ABI decoding.
// Fields correspond to parameters across all monitored events.
// Use pointers for optional fields (fields not present in all events).
type DecodedEvent struct {
	// Common across multiple events
	Amount      *big.Int `json:"amount,omitempty"`
	ProjectId   *big.Int `json:"projectId,omitempty"`   // Note: Assuming ProjectCreatedEvent.ProjectId was typo 'epoch'
	EpochNumber *big.Int `json:"epochNumber,omitempty"` // Used in RewardClaim* events

	// FundsAddedEvent
	Funder *common.Address `json:"funder,omitempty"`

	// FundsWithdrawnEvent / ProjectRewardsRecipientUpdatedEvent
	Recipient *common.Address `json:"recipient,omitempty"`

	// InitializedEvent
	Version *big.Int `json:"version,omitempty"`

	// InvalidRewardClaimAmountEvent
	RequestEpochNumber *big.Int `json:"requestEpochNumber,omitempty"`
	DiffAmmount        *big.Int `json:"diffAmmount,omitempty"`

	// ProjectAddedEvent / ProjectOwnerUpdatedEvent
	Owner *common.Address `json:"owner,omitempty"`

	// ProjectAddedEvent
	RewardsRecipient *common.Address   `json:"rewardsRecipient,omitempty"`
	MetadataUri      *string           `json:"metadataUri,omitempty"` // Also used in ProjectMetadataUriUpdatedEvent
	ActiveFromEpoch  *big.Int          `json:"activeFromEpoch,omitempty"`
	Contracts        *[]common.Address `json:"contracts,omitempty"` // Slice of addresses

	// ProjectContractAddedEvent / ProjectContractRemovedEvent
	ContractAddress *common.Address `json:"contractAddress,omitempty"`

	// ProjectEnabledEvent
	EnabledOnEpochNumber *big.Int `json:"enabledOnEpochNumber,omitempty"`

	// ProjectSuspendedEvent
	SuspendedOnEpochNumber *big.Int `json:"suspendedOnEpochNumber,omitempty"`

	// RewardClaimConfirmationsLimitUpdatedEvent / RewardClaimEpochsLimitUpdatedEvent
	Limit *big.Int `json:"limit,omitempty"`

	// RoleAdminChangedEvent
	Role              *common.Hash `json:"role,omitempty"` // Also used in RoleGrantedEvent, RoleRevokedEvent
	PreviousAdminRole *common.Hash `json:"previousAdminRole,omitempty"`
	NewAdminRole      *common.Hash `json:"newAdminRole,omitempty"`

	// RoleGrantedEvent / RoleRevokedEvent
	Account *common.Address `json:"account,omitempty"`
	Sender  *common.Address `json:"sender,omitempty"`

	// SfcAddressUpdatedEvent
	SfcAddress *common.Address `json:"sfcAddress,omitempty"`

	// UpgradedEvent
	Implementation *common.Address `json:"implementation,omitempty"`

	// SfcFeeUpdatedEvent
	Fee *big.Int `json:"fee,omitempty"`

	// --- Metadata ---
	Log       types.Log `json:"log"`       // The raw log entry
	EventName string    `json:"eventName"` // Name of the decoded event
}

// Helper function to safely get string from *string pointer
func SafeString(s *string) string {
	if s != nil {
		return *s
	}
	return ""
}

// Helper function to safely get string from *big.Int pointer
func SafeBigIntString(b *big.Int) string {
	if b != nil {
		return b.String()
	}
	return "" // Or "0" or "" depending on desired BQ representation for nil
}

// Helper function to safely get hex string from *common.Address pointer
func SafeAddressHex(a *common.Address) string {
	if a != nil {
		return a.Hex()
	}
	return ""
}

// Helper function to safely get hex string from *common.Hash pointer
func SafeHashHex(h *common.Hash) string {
	if h != nil {
		return h.Hex()
	}
	return ""
}

// Helper function to safely get slice of hex strings from *[]common.Address pointer
func SafeAddressSliceHex(addrs *[]common.Address) []string {
	if addrs == nil {
		return nil // Represent as NULL in BQ
	}
	hexAddrs := make([]string, len(*addrs))
	for i, addr := range *addrs {
		hexAddrs[i] = addr.Hex()
	}
	return hexAddrs
}

func init() {
	// Register custom types
	beam.RegisterType(reflect.TypeOf((*DecodedEvent)(nil)).Elem())
	beam.RegisterType(reflect.TypeOf((*big.Int)(nil))) // Register big.Int if not done elsewhere
	beam.RegisterType(reflect.TypeOf((*common.Address)(nil)))
	beam.RegisterType(reflect.TypeOf((*common.Hash)(nil)))
}
