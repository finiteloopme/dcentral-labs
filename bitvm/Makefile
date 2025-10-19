.PHONY: start-regtest

# Commands
RIC := run-in-container.sh

# Variables
BTC_SERVER_CONTAINER=bitcoin-server

start-regtest:
	EXTRA_ARGS="--name ${BTC_SERVER_CONTAINER}" $(RIC) bitcoin \
		-printtoconsole \
		-regtest=1

connect-to-server:
	EXTRA_ARGS="--user bitcoin ${BTC_SERVER_CONTAINER}" $(RIC) bitcoin bash