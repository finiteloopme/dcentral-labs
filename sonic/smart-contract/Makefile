
include .env

.PHONY: deploy-contract
deploy-contract:
	forge create \
		--chain-id $(CHAIN_ID) \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		$(SMART_CONTRACT_FILE)