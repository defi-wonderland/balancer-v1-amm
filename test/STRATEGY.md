# Outline

There are 5 files to cover (BConst is a contract of public protocol-wide constants):
BFactory: deployer, approx 40sloc
BMath: contract wrapping math logic (shouldn't this be an internal lib tho?)
BNum: contract wrapping arithmetic op (same remark)
BPool: the main contract, roughly 400sloc
BToken: extends erc20

## Interdependencies
Factory deploys a pool and can "collect" from the pool
Pool inherit btoken (which represents a LP) and bmath
Bmath uses bnum

## Approach

Beside BTT unit test and happy path integration, we could prioritize (ie only do the second tool if we have extra-time, when applicable):
- symbolic execution for the BMath and BNum contracts (as they're fully stateless)
- Echidna for BFactory (internal), BToken (internal, reusing ToB erc20 properties), then protocol-wide (factory deploying bpool)
Then slither-mutate.

Setup for protocol-wide *looks* pretty simple (using the factory) - tbc

## Notes
The bmath corresponding equations are:

Spot price:
$\text{spotPrice} = \frac{\text{tokenBalanceIn}/\text{tokenWeightIn}}{\text{tokenBalanceOut}/\text{tokenWeightOut}} \cdot \frac{1}{1 - \text{swapFee}}$

Out given in:,
$\text{tokenAmountOut} = \text{tokenBalanceOut} \cdot \left( 1 - \left( \frac{\text{tokenBalanceIn}}{\text{tokenBalanceIn} + \left( \text{tokenAmountIn} \cdot \left(1 - \text{swapFee}\right)\right)} \right)^{\frac{\text{tokenWeightIn}}{\text{tokenWeightOut}}} \right)$

In given out:
$\text{tokenAmountIn} = \frac{\text{tokenBalanceIn} \cdot \left( \frac{\text{tokenBalanceOut}}{\text{tokenBalanceOut} - \text{tokenAmountOut}} \right)^{\frac{\text{tokenWeightOut}}{\text{tokenWeightIn}}} - 1}{1 - \text{swapFee}}$

Pool out given single in
$\text{poolAmountOut} = \left(\frac{\text{tokenAmountIn} \cdot \left(1 - \left(1 - \frac{\text{tokenWeightIn}}{\text{totalWeight}}\right) \cdot \text{swapFee}\right) + \text{tokenBalanceIn}}{\text{tokenBalanceIn}}\right)^{\frac{\text{tokenWeightIn}}{\text{totalWeight}}} \cdot \text{poolSupply} - \text{poolSupply}$

Single in given pool out
$\text{tokenAmountIn} = \frac{\left(\frac{\text{poolSupply} + \text{poolAmountOut}}{\text{poolSupply}}\right)^{\frac{1}{\frac{\text{weightIn}}{\text{totalWeight}}}} \cdot \text{balanceIn} - \text{balanceIn}}{\left(1 - \frac{\text{weightIn}}{\text{totalWeight}}\right) \cdot \text{swapFee}}$

Single out given pool in
$\text{tokenAmountOut} = \left( \text{tokenBalanceOut} - \left( \frac{\text{poolSupply} - \left(\text{poolAmountIn} \cdot \left(1 - \text{exitFee}\right)\right)}{\text{poolSupply}} \right)^{\frac{1}{\frac{\text{tokenWeightOut}}{\text{totalWeight}}}} \cdot \text{tokenBalanceOut} \right) \cdot \left(1 - \left(1 - \frac{\text{tokenWeightOut}}{\text{totalWeight}}\right) \cdot \text{swapFee}\right)$

Pool in given single out
$\text{poolAmountIn} = \frac{\text{poolSupply} - \left( \frac{\text{tokenBalanceOut} - \frac{\text{tokenAmountOut}}{1 - \left(1 - \frac{\text{tokenWeightOut}}{\text{totalWeight}}\right) \cdot \text{swapFee}}}{\text{tokenBalanceOut}} \right)^{\frac{\text{tokenWeightOut}}{\text{totalWeight}}} \cdot \text{poolSupply}}{1 - \text{exitFee}}$