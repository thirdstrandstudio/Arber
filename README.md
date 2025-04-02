# Arber - Arbitrage Smart Contract

An Ethereum-based smart contract system that automates arbitrage opportunities across multiple decentralized exchanges. Supported on any EVM networks

[![Get Professional Version](https://img.shields.io/badge/Upgrade%20to-Professional%20Version-blue?style=for-the-badge)](https://thirdstrandstudio.com/products/arber)

## Overview

Arber is a sophisticated arbitrage system that identifies and executes profitable trades across different DEXs (Decentralized Exchanges) such as Uniswap, PancakeSwap, and more. The contract is designed to:

1. Check price differences between token pairs across various DEXs
2. Calculate potential profits including gas costs
3. Execute trades only when profitable
4. Allow for upgradability via the UUPS (Universal Upgradeable Proxy Standard) pattern


For testing we ignored gas fees and tested a few transactions:

1.
https://bscscan.com/tx/0xd80178b10213d3011996a04aaa3f74887a208f85220181ae1a2340bee773e015

![image](https://github.com/user-attachments/assets/917ccae5-03d3-46e2-a562-6d172b951998)


2. https://bscscan.com/tx/0x97701d6f17fcaf94860583d6b5b2bd0fce62461431ec987ae15b3d1649bf6511

![image](https://github.com/user-attachments/assets/9bfdc460-2dc0-4adc-b7c1-42b60d436c46)


3. https://bscscan.com/tx/0xe403af85d253f26ccbf465188614619df1ba548a856f837b4144d78b0361455b

![image](https://github.com/user-attachments/assets/7d17e374-f3c8-4fe5-8a33-ad5b8c55cd25)

## Router Compatibility

### Uniswap V2 Interface Support Only

The Arber contract is **designed to work exclusively with routers that implement the Uniswap V2 interface** (`IUniswapV2Router02`). This includes many popular DEXs that maintain backward compatibility with this interface. **Uniswap V3 and other newer DEX interfaces are not supported** in this version.

### Supported DEXs

The default deployment includes the following routers:

- PancakeSwap V2 (`0x10ED43C718714eb63d5aA57B78B54704E256024E`)
- Uniswap V2 (`0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24`) 
- ApeSwap (`0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7`)
- SushiSwap (`0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506`)

You can add or remove routers using the provided scripts as long as they implement the Uniswap V2 router interface. The contract's functionality depends on these routers providing consistent responses to the `getAmountsOut` method.

## Professional Version Available

### [⚡ Upgrade to Professional Arber ⚡](https://thirdstrandstudio.com/products/arber)

The open-source version you're viewing provides basic arbitrage functionality. Our professional version includes advanced features:

#### Advanced Features
- **Mempool Monitoring**: Detects price changes in the mempool and executes arbitrage in the same block
- **AI-Powered Path Finding**: Uses OptaPlanner constraint solver AI to identify optimal arbitrage paths
- **Multi-Path Arbitrage**: Extends beyond 2-path arbitrage to identify complex profitable routes across multiple tokens and DEXs
- **Lightning-Fast Execution**: Optimized for minimal latency with concurrent processing
- **Advanced Analytics Dashboard**: Real-time performance tracking and visualization
- **Automated Trade Execution**: Fully automated system requiring minimal oversight

[![Arber Professional](https://img.shields.io/badge/Arber-Professional-orange?style=for-the-badge)](https://thirdstrandstudio.com/products/arber)

The professional version is available through [Third Strand Studio](https://thirdstrandstudio.com/products/arber) and includes setup support.

## Key Features

- **Automated Arbitrage**: Identifies and executes profitable arbitrage opportunities
- **Multi-Router Support**: Works across multiple DEXs simultaneously
- **Gas-Aware**: Accounts for gas costs when calculating profitability
- **View Function Profitability Check**: Uses `shouldIteratePairList` view function to check if trades will be profitable before execution
- **Upgradeable Design**: Uses OpenZeppelin's UUPS pattern for contract upgrades

## Understanding Profitability Calculations

### How Arber Determines Profit

The Arber contract uses a sophisticated process to identify and execute only profitable arbitrage opportunities:

1. **Price Comparison**: The contract compares the price of a token pair across different DEXs (routers) to find disparities.

2. **WETH-Based Gas Cost Calculation**: 
   - Arber uses Wrapped Ether (WETH) as a base currency to estimate gas costs in terms of token value
   - When calculating if a trade is profitable, it converts the gas cost to an equivalent amount of the token being traded
   - This allows the contract to accurately determine if the profit exceeds the cost of executing the transaction

3. **Calculation Process**:
   - First, the contract obtains the best buy and sell prices across all configured routers
   - Then, it calculates the potential profit: `sellAmount - amountIn`
   - Next, it estimates the gas cost in WETH and converts it to token0 value using `getWethPriceInToken0`
   - Finally, it compares: if `profit > wethPriceInToken0`, the trade is profitable

### Supported Tokens

The contract is **not limited to stablecoins**. It can work with any ERC20 token pairs that:

1. Have sufficient liquidity on at least two different DEXs
2. Can be priced relative to WETH (directly or indirectly)

For optimal operation, token pairs should:
- Have a price path to WETH on at least one router
- Have enough liquidity to execute trades without significant slippage
- Exhibit price differences across different exchanges

### Pricing Mechanism

The `getWethPaths` function identifies possible paths between tokens and WETH, which are used to:
1. Convert gas costs (denominated in ETH) to token values
2. Provide a common denomination for comparing different token pairs
3. Allow the contract to work with a wide variety of tokens, not just stablecoins

If a token doesn't have a direct path to WETH, the contract attempts to find a path through the paired token.

## For Non-Technical Users

### Getting Started

1. **Deploy the Contract**: If you haven't already, work with a developer to deploy the Arber contract to the blockchain.

2. **Fund Your Contract**: After deployment, you need to deposit funds to enable trading:
   - Get the address of your deployed contract
   - Transfer ERC20 tokens you want to use for arbitrage to this address
   - For ETH networks, you'll need to wrap your ETH into WETH first, then transfer

3. **Daily Operation**:
   - Use a blockchain interface (like Etherscan) to interact with your contract
   - Call the `shouldIteratePairList` function first to check for profitable opportunities
   - If it returns `shouldIterate: true`, then call the `iteratePairList` function with the same parameters to execute trades

### Checking for Profitable Trades

1. Go to your contract on Etherscan or another blockchain explorer
2. Connect your wallet (must be the contract owner)
3. Find the "Read Contract" section
4. Call `shouldIteratePairList` with these parameters:
   - `start`: 0 (start from the beginning of your pair list)
   - `n`: Number of pairs to check (e.g., 10)
   - `amountIn`: Amount of input token to use (in wei)
   - `slippageTolerance`: Your acceptable slippage (e.g., 50 = 0.5%)
   - `gasUsed`: Estimated gas for transaction (e.g., 200000)

5. Check the result:
   - If `shouldIterate` is `true`, proceed to execute the trade
   - Note the other returned values as you'll need them for the next step

### Executing Profitable Trades

1. If the previous step showed profitable opportunities, go to "Write Contract" section
2. Call `iteratePairList` with:
   - `start`: Use the value returned from `shouldIteratePairList`
   - `n`: 1 (to execute just the profitable pair)
   - `amountIn`: Use the value returned from `shouldIteratePairList`
   - `slippageTolerance`: Use the value returned from `shouldIteratePairList`
   - `gasUsed`: Use the value returned from `shouldIteratePairList`
   - `dryRun`: false (to actually execute the trade)

3. Confirm the transaction and pay the gas fee

### Withdrawing Profits

1. To withdraw tokens from the contract, go to "Write Contract" section
2. Call `withdrawTokens` with:
   - `token`: The address of the token you want to withdraw

### Important Notes

- Only the contract owner can execute trades and withdrawals
- Always check profitability before executing trades
- Monitor your contract's performance and adjust parameters as needed
- Consider the gas costs of transactions when evaluating profitability

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
