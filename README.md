<h1 align=center><code>Balancer CoW AMM</code></h1>

**Balancer CoW AMM** is an automated **portfolio manager**, **liquidity provider**, and **price sensor**, that allows swaps to be executed via the CoW Protocol.

Balancer is based on an N-dimensional invariant surface which is a generalization of the constant product formula described by Vitalik Buterin and proven viable by the popular Uniswap dapp.

## Development

Most users will want to consume the ABI definitions for BPool, BCoWPool, BFactory and BCoWFactory.

This project follows the standard Foundry project structure. 

```
yarn build   # build artifacts to `out/`
yarn test    # run the tests
```

## Changes on BPool from (Balancer V1)[https://github.com/balancer/balancer-core]
- Migrated to Foundry project structure
- Implementation of interfaces with Natspec documentation
- Replaced `require(cond, 'STRING')` for `if(!cond) revert CustomError()`
- Bumped Solidity version from `0.5.12` to `0.8.25` (required for transient storage)
  - Added explicit `unchecked` blocks to `BNum` operations (to avoid Solidity overflow checks)
- Deprecated `Record.balance` storage (in favour of `ERC20.balanceOf(address(this))`)
- Deprecated `gulp` method (not needed since reading ERC20 balances)
- Deprecated manageable pools:
  - Deprecated `isPublicSwap` mechanism (for pools to be swapped before being finalized)
  - Deprecated `rebind` method (in favour of `bind + unbind + bind`)
  - Deprecated exit fee on `unbind` (since the pool is not supposed to have collected any fees)
- Deprecated `BBaseToken` (in favour of OpenZeppelin `ERC20` implementation)
- Deprecated `BColor` and `BBronze` (unused contracts)
- Deprecated `Migrations` contract (not needed)
- Added an `_afterFinalize` hook (to be called at the end of the finalize routine)

## Features on BCoWPool (added via inheritance to BPool)
- Immutably stores CoW Protocol's `SolutionSettler` and `VaultRelayer` addresses at deployment
- Immutably stores Cow Protocol's a Domain Separator at deployment (to avoid replay attacks)
- Gives infinite ERC20 approval to the CoW Protocol's `VaultRelayer` contract
- Implements IERC1271 `isValidSignature` method to allow for validating intentions of swaps
- Implements a `commit` method to avoid multiple swaps from conflicting with each other
- Allows the controller to allow only one `GPv2Order.appData` at a time
- Validates the `GPv2Order` requirements before allowing the swap

## Creating a Pool
- Create a new pool by calling `IBFactory.newBPool()`
- Give ERC20 allowance to the pool by calling `IERC20.approve(pool, amount)`
- Bind tokens one by one by calling `IBPool.bind(token, amount, weight)`
  - The amount represents the initial balance of the token in the pool (pulled from the caller's balance)
  - The weight represents the intended distribution of value between the tokens in the pool
- Modify the pool's swap fee by calling `IBPool.setSwapFee(fee)`
- Finalize the pool by calling `IBPool.finalize()`

This actions allow the Pool to be directly swapped by users. In the case of BCoWPool, the pool will need the pool creator to perform another action in order to allow CoW Protocol swaps:
- Call `IBCoWPool.enableTrading(appData)`
  - The `appData` is a unique identifier for the swap origin (used to avoid replay attacks)