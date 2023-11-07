-include .env

# Forge Scripts


production-deployment:
	forge script script/Deploy.s.sol --rpc-url ${ARBNODEURL} --broadcast --etherscan-api-key ${ETHERSCAN_TOKEN} --verify

dryrun-deployment:
	forge script script/Deploy.s.sol --rpc-url ${ARBNODEURL}
