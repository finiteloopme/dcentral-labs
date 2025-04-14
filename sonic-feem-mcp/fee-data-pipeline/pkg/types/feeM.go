package types

// import (
// 	"math/big"

// 	"github.com/ethereum/go-ethereum/common"
// )

// // FundsAdded represents the FundsAdded event
// type FundsAdded struct {
// 	Funder common.Address `json:"funder,omitempty"` // indexed
// 	Amount *big.Int       `json:"amount,omitempty"`
// }

// // FundsWithdrawn represents the FundsWithdrawn event
// type FundsWithdrawn struct {
// 	Recipient common.Address `json:"recipient,omitempty"` // indexed
// 	Amount    *big.Int       `json:"amount,omitempty"`
// }

// // Initialized represents the Initialized event
// type Initialized struct {
// 	Version *big.Int `json:"version,omitempty"`
// }

// // InvalidRewardClaimAmount represents the InvalidRewardClaimAmount event
// type InvalidRewardClaimAmount struct {
// 	ProjectId          *big.Int `json:"projectId,omitempty"` // indexed
// 	RequestEpochNumber *big.Int `json:"requestEpochNumber,omitempty"`
// 	Amount             *big.Int `json:"amount,omitempty"`
// 	DiffAmount         *big.Int `json:"diffAmount,omitempty"`
// }

// // ProjectAdded represents the ProjectAdded event
// type ProjectAdded struct {
// 	ProjectId        *big.Int         `json:"projectId,omitempty"`        // indexed
// 	Owner            common.Address   `json:"owner,omitempty"`            // indexed
// 	RewardsRecipient common.Address   `json:"rewardsRecipient,omitempty"` // indexed
// 	MetadataUri      string           `json:"metadataUri,omitempty"`
// 	ActiveFromEpoch  *big.Int         `json:"activeFromEpoch,omitempty"`
// 	Contracts        []common.Address `json:"contracts,omitempty"`
// }

// // ProjectContractAdded represents the ProjectContractAdded event
// type ProjectContractAdded struct {
// 	ProjectId       *big.Int       `json:"projectId,omitempty"`       // indexed
// 	ContractAddress common.Address `json:"contractAddress,omitempty"` // indexed
// }

// // ProjectContractRemoved represents the ProjectContractRemoved event
// type ProjectContractRemoved struct {
// 	ProjectId       *big.Int       `json:"projectId,omitempty"`       // indexed
// 	ContractAddress common.Address `json:"contractAddress,omitempty"` // indexed
// }

// // ProjectEnabled represents the ProjectEnabled event
// type ProjectEnabled struct {
// 	ProjectId            *big.Int `json:"projectId,omitempty"` // indexed
// 	EnabledOnEpochNumber *big.Int `json:"enabledOnEpochNumber,omitempty"`
// }

// // ProjectMetadataUriUpdated represents the ProjectMetadataUriUpdated event
// type ProjectMetadataUriUpdated struct {
// 	ProjectId   *big.Int `json:"projectId,omitempty"` // indexed
// 	MetadataUri string   `json:"metadataUri,omitempty"`
// }

// // ProjectOwnerUpdated represents the ProjectOwnerUpdated event
// type ProjectOwnerUpdated struct {
// 	ProjectId *big.Int       `json:"projectId,omitempty"` // indexed
// 	Owner     common.Address `json:"owner,omitempty"`
// }

// // ProjectRewardsRecipientUpdated represents the ProjectRewardsRecipientUpdated event
// type ProjectRewardsRecipientUpdated struct {
// 	ProjectId *big.Int       `json:"projectId,omitempty"` // indexed
// 	Recipient common.Address `json:"recipient,omitempty"`
// }

// // ProjectSuspended represents the ProjectSuspended event
// type ProjectSuspended struct {
// 	ProjectId              *big.Int `json:"projectId,omitempty"` // indexed
// 	SuspendedOnEpochNumber *big.Int `json:"suspendedOnEpochNumber,omitempty"`
// }

// // RewardClaimCanceled represents the RewardClaimCanceled event
// type RewardClaimCanceled struct {
// 	ProjectId   *big.Int `json:"projectId,omitempty"` // indexed
// 	EpochNumber *big.Int `json:"epochNumber,omitempty"`
// }

// // RewardClaimCompleted represents the RewardClaimCompleted event
// type RewardClaimCompleted struct {
// 	ProjectId   *big.Int `json:"projectId,omitempty"` // indexed
// 	EpochNumber *big.Int `json:"epochNumber,omitempty"`
// 	Amount      *big.Int `json:"amount,omitempty"`
// }

// // RewardClaimConfirmationsLimitUpdated represents the RewardClaimConfirmationsLimitUpdated event
// type RewardClaimConfirmationsLimitUpdated struct {
// 	Limit *big.Int `json:"limit,omitempty"`
// }

// // RewardClaimEpochsLimitUpdated represents the RewardClaimEpochsLimitUpdated event
// type RewardClaimEpochsLimitUpdated struct {
// 	Limit *big.Int `json:"limit,omitempty"`
// }

// // RewardClaimRequested represents the RewardClaimRequested event
// type RewardClaimRequested struct {
// 	ProjectId          *big.Int `json:"projectId,omitempty"` // indexed
// 	RequestEpochNumber *big.Int `json:"requestEpochNumber,omitempty"`
// }

// // RoleAdminChanged represents the RoleAdminChanged event
// type RoleAdminChanged struct {
// 	Role              [32]byte `json:"role,omitempty"`              // indexed
// 	PreviousAdminRole [32]byte `json:"previousAdminRole,omitempty"` // indexed
// 	NewAdminRole      [32]byte `json:"newAdminRole,omitempty"`      // indexed
// }

// // RoleGranted represents the RoleGranted event
// type RoleGranted struct {
// 	Role    [32]byte       `json:"role,omitempty"`    // indexed
// 	Account common.Address `json:"account,omitempty"` // indexed
// 	Sender  common.Address `json:"sender,omitempty"`  // indexed
// }

// // RoleRevoked represents the RoleRevoked event
// type RoleRevoked struct {
// 	Role    [32]byte       `json:"role,omitempty"`    // indexed
// 	Account common.Address `json:"account,omitempty"` // indexed
// 	Sender  common.Address `json:"sender,omitempty"`  // indexed
// }

// // SfcAddressUpdated represents the SfcAddressUpdated event
// type SfcAddressUpdated struct {
// 	SfcAddress common.Address `json:"sfcAddress,omitempty"`
// }

// // Upgraded represents the Upgraded event
// type Upgraded struct {
// 	Implementation common.Address `json:"implementation,omitempty"` // indexed
// }
