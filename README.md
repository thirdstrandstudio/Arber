# Arber - Arbitrage Smart Contract

An Ethereum-based smart contract system that automates arbitrage opportunities across multiple decentralized exchanges.

## Overview

Arber is a sophisticated arbitrage system that identifies and executes profitable trades across different DEXs (Decentralized Exchanges) such as Uniswap, PancakeSwap, and more. The contract is designed to:

1. Check price differences between token pairs across various DEXs
2. Calculate potential profits including gas costs
3. Execute trades only when profitable
4. Allow for upgradability via the UUPS (Universal Upgradeable Proxy Standard) pattern

## Key Features

- **Automated Arbitrage**: Identifies and executes profitable arbitrage opportunities
- **Multi-Router Support**: Works across multiple DEXs simultaneously
- **Gas-Aware**: Accounts for gas costs when calculating profitability
- **View Function Profitability Check**: Uses `shouldIteratePairList` view function to check if trades will be profitable before execution
- **Upgradeable Design**: Uses OpenZeppelin's UUPS pattern for contract upgrades

## Contract Architecture

The contract system consists of:

- `ArberUpgradeable.sol`: Main contract implementing arbitrage logic
- `IArberUpgradeable.sol`: Interface defining the contract's functions and structures
- Various deployment and interaction scripts

## How It Works

1. The contract maintains a list of token pairs and available routers (DEXs)
2. Users or automated systems call `shouldIteratePairList()` to check if arbitrage is profitable
3. If `shouldIterate` is true, then `iteratePairList()` can be called to execute the profitable trade
4. Trades are executed atomically to prevent front-running

## Setup and Deployment

### Prerequisites

- Node.js and npm
- Foundry (forge, anvil, cast)
- Access to Ethereum RPC endpoint

### Installation

```bash
git clone https://github.com/yourusername/Arber.git
cd Arber
npm install
```

### Deployment

1. Set up your environment variables in a `.env` file:

```
PRIVATE_KEY=your_private_key
WETH=your_weth_address
```

2. Deploy the contract:

```bash
forge script scripts/DeployArberUpgradeable.sol --rpc-url your_rpc_url --broadcast
```

3. Add routers and token pairs:

```bash
# Add a router
ROUTER_ADDRESS=your_router_address ARBER_ADDRESS=deployed_contract_address forge script scripts/AddRouter.sol --rpc-url your_rpc_url --broadcast

# Add a token pair
TOKEN0_ADDRESS=first_token_address TOKEN1_ADDRESS=second_token_address ARBER_ADDRESS=deployed_contract_address forge script scripts/AddTokenPair.sol --rpc-url your_rpc_url --broadcast
```

## Usage

### Check for Profitable Opportunities

```solidity
// In a script or contract
IArberUpgradeable.IteratePairListInput memory result = arber.shouldIteratePairList(
    0,          // start index
    11,         // number of pairs to check
    1000000 gwei, // amount in
    0,          // slippage tolerance
    100         // gas used estimation
);

if (result.shouldIterate) {
    // Execute the profitable trade
    arber.iteratePairList(
        result.start,
        1, // Only execute the profitable pair
        result.amountIn,
        result.slippageTolerance,
        result.gasUsed,
        false // Not a dry run
    );
}
```

## Scripts

| Script | Description |
|--------|-------------|
| `DeployArberUpgradeable.sol` | Deploys the contract with initial routers |
| `AddRouter.sol` | Adds a new router (DEX) to the contract |
| `RemoveRouter.sol` | Removes a router from the contract |
| `AddTokenPair.sol` | Adds a new token pair for arbitrage monitoring |
| `IteratePairList.sol` | Checks and executes profitable arbitrage opportunities |
| `GetPairsScript.sol` | Lists all token pairs registered in the contract |
| `UpgradeArberScript.sol` | Upgrades the contract implementation |

## Contract Functions

### Core Functions

- `shouldIteratePairList(uint256 start, uint256 n, uint256 amountIn, uint256 slippageTolerance, uint256 gasUsed)`: View function that checks if arbitrage will be profitable
- `iteratePairList(uint256 start, uint256 n, uint256 amountIn, uint256 slippageTolerance, uint256 gasUsed, bool dryRun)`: Executes arbitrage operations
- `executeArbitrage(address token0, address token1, uint256 amountIn, uint256 slippageTolerance, uint256 gasUsed, bool dryRun)`: Executes a specific arbitrage opportunity

### Management Functions

- `addRouter(address router)`: Adds a new DEX router
- `removeRouter(address router)`: Removes a DEX router
- `addTokenPair(address token0, address token1)`: Adds a new token pair
- `clearPairList()`: Clears all token pairs
- `withdrawTokens(address token)`: Withdraws tokens from the contract

## License

MIT 