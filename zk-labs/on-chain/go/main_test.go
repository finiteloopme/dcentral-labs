package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestTransferEgg(t *testing.T) {
	cfg := &Config{}
	client := NewClient(cfg)
	ownerKey := GetKeyFromHexPrivateKey(cfg.UserKeys.Owner)
	initial := client.ZKPBalanceOf(ownerKey.Address.Hex())
	// user1Key := GetKeyFromHexPrivateKey(cfg.UserKeys.User1)
	// user2Key := GetKeyFromHexPrivateKey(cfg.UserKeys.User2)
	// initial := client.ZKPBalanceOf(user1Key.Address.Hex())
	// tx := client.TransferZKP(cfg.UserKeys.Owner, user1Key.Address, big.NewInt(10))
	assert.NotNil(t, initial, "Expected a valid balance")
	assert.Greater(t, initial.Uint64(), uint64(0))
	// assert.True(t, initial.Cmp(big.NewInt(0)) == -1, "Expected more than 0.  Received: %v", initial)
	// log.Info(fmt.Sprintf("Balance of owner is: %v", client.ZKPBalanceOf(ownerKey.Address.Hex())))
	// log.Info(fmt.Sprintf("Balance of user1 is: %v", client.ZKPBalanceOf(user1Key.Address.Hex())))
	// client.TransferZKP(cfg.UserKeys.Owner, user1Key.Address, big.NewInt(10))
	// log.Info(fmt.Sprintf("Balance of owner is: %v", client.ZKPBalanceOf(ownerKey.Address.Hex())))
	// log.Info(fmt.Sprintf("Balance of user1 is: %v", client.ZKPBalanceOf(user1Key.Address.Hex())))
	// client.AwardAnEgg(cfg.UserKeys.Owner, user1Key.Address)
	// client.AwardFeather(cfg.UserKeys.Owner, user2Key.Address)

	// log.Info((fmt.Sprintf("Owner of egg1 is: %v", client.WhoOwnsTheEgg(big.NewInt(1)))))
	// log.Info((fmt.Sprintf("Owner of feather1 is: %v", client.WhoOwnsTheFeather(big.NewInt(1)))))
}
