RPC_URL=https://fragrant-purple-sunset.matic.quiknode.pro/

update:
	forge script "scripts/UpgradeArberScript.sol:UpgradeArberScript" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"

iterate-pair-list:
	forge script "scripts/IteratePairList.sol:IteratePairList" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"

deploy-arber:
	forge script "scripts/DeployArberUpgradeable.sol:DeployArberUpgradeable" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"


