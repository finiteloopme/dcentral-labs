package svc

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/finiteloopme/dcentral-labs/chain-data-stream/pkg/types"
	"github.com/finiteloopme/goutils/pkg/log"
)

// Downloads ABI for the given smart contract address
func (client *Client) DownloadABI(address string) ([]byte, error) {
	// e.g. https://api.etherscan.io/api?module=contract&action=getabi&address=0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD&format=raw

	resp, err := http.Get(fmt.Sprintf("https://api.etherscan.io/api?module=contract&action=getabi&address=%s&format=raw", address))
	//code, err := client.ethclient.CodeAt(context.Background(), common.HexToAddress(address), nil)

	if err != nil {
		log.Info(fmt.Sprintf("Error retrieving ABI for: %s\n%s", address, err.Error()))
		return nil, err
	}

	return io.ReadAll(resp.Body)
	// return code, err
}

func ParseABI(rawInput []byte) (*abi.ABI, error) {
	var parsedABI abi.ABI
	err := json.Unmarshal(rawInput, &parsedABI)
	if err != nil {
		log.Info("Encountered unexpected error: " + err.Error())
		return nil, err
	}

	return &parsedABI, nil
}

func DecodeABI(parsedABI *abi.ABI) (*types.SwapFunction, error) {
	var swap types.SwapFunction
	return &swap, nil
}
