RPC_URL=https://young-still-wish.bsc.quiknode.pro/5ee0cd7020cfcc8c5d36b7fe2fbfb376518d8dff/

update:
	forge script "scripts/UpgradeArberScript.sol:UpgradeArberScript" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"

iterate-pair-list:
	forge script "scripts/IteratePairList.sol:IteratePairList" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"

add-token-pair:
	forge script "scripts/AddTokenPair.sol:AddTokenPair" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"

deploy:
	forge script "scripts/DeployArberUpgradeable.sol:DeployArberUpgradeable" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"

get-pairs:
	forge script "scripts/GetPairsScript.sol:GetPairsScript" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"

remove-router:
	forge script "scripts/RemoveRouter.sol:RemoveRouter" --broadcast --verify -vvvv --rpc-url "$(RPC_URL)"
