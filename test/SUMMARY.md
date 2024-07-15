# Outline

There are 7 files to cover (B(cow)Const are contracts containing public protocol-wide constants):
BCoWFactory: deployer for cow pools
BCoWPool: adding signature validation to BPool
BFactory: deployer, approx 40sloc
BMath: contract wrapping math logic
BNum: contract wrapping arithmetic op
BPool: the main contract, roughly 400sloc
BToken: extends erc20

## Interdependencies
BCoWFactory deploys a bcowpool
BCoWPool is a bpool which adds signature validation
Factory deploys a pool and can "collect" from the pool
Pool inherit btoken (which represents a LP) and bmath
Bmath uses bnum

## Approach

Echidna should be prioritized, then halmos should be particularly easy especially for the math libs, for which the implementations will be pretty similar.

Then slither-mutate on the whole test base

Setup for protocol-wide *looks* pretty simple (using the factory) - tbc

nb 14 means if token in == token out, people just give tokens to the pool, intended?


## Notes
The bmath corresponding equations are:

`Spot price:`
$\text{spotPrice} = \frac{\text{tokenBalanceIn}/\text{tokenWeightIn}}{\text{tokenBalanceOut}/\text{tokenWeightOut}} \cdot \frac{1}{1 - \text{swapFee}}$


`Out given in:`
$\text{tokenAmountOut} = \text{tokenBalanceOut} \cdot \left( 1 - \left( \frac{\text{tokenBalanceIn}}{\text{tokenBalanceIn} + \left( \text{tokenAmountIn} \cdot \left(1 - \text{swapFee}\right)\right)} \right)^{\frac{\text{tokenWeightIn}}{\text{tokenWeightOut}}} \right)$


`In given out:`
$\text{tokenAmountIn} = \frac{\text{tokenBalanceIn} \cdot \left( \frac{\text{tokenBalanceOut}}{\text{tokenBalanceOut} - \text{tokenAmountOut}} \right)^{\frac{\text{tokenWeightOut}}{\text{tokenWeightIn}}} - 1}{1 - \text{swapFee}}$


`Pool out given single in`
$\text{poolAmountOut} = \left(\frac{\text{tokenAmountIn} \cdot \left(1 - \left(1 - \frac{\text{tokenWeightIn}}{\text{totalWeight}}\right) \cdot \text{swapFee}\right) + \text{tokenBalanceIn}}{\text{tokenBalanceIn}}\right)^{\frac{\text{tokenWeightIn}}{\text{totalWeight}}} \cdot \text{poolSupply} - \text{poolSupply}$


`Single in given pool out`
$\text{tokenAmountIn} = \frac{\left(\frac{\text{poolSupply} + \text{poolAmountOut}}{\text{poolSupply}}\right)^{\frac{1}{\frac{\text{weightIn}}{\text{totalWeight}}}} \cdot \text{balanceIn} - \text{balanceIn}}{\left(1 - \frac{\text{weightIn}}{\text{totalWeight}}\right) \cdot \text{swapFee}}$


`Single out given pool in`
$\text{tokenAmountOut} = \left( \text{tokenBalanceOut} - \left( \frac{\text{poolSupply} - \left(\text{poolAmountIn} \cdot \left(1 - \text{exitFee}\right)\right)}{\text{poolSupply}} \right)^{\frac{1}{\frac{\text{tokenWeightOut}}{\text{totalWeight}}}} \cdot \text{tokenBalanceOut} \right) \cdot \left(1 - \left(1 - \frac{\text{tokenWeightOut}}{\text{totalWeight}}\right) \cdot \text{swapFee}\right)$


`Pool in given single out`
$\text{poolAmountIn} = \frac{\text{poolSupply} - \left( \frac{\text{tokenBalanceOut} - \frac{\text{tokenAmountOut}}{1 - \left(1 - \frac{\text{tokenWeightOut}}{\text{totalWeight}}\right) \cdot \text{swapFee}}}{\text{tokenBalanceOut}} \right)^{\frac{\text{tokenWeightOut}}{\text{totalWeight}}} \cdot \text{poolSupply}}{1 - \text{exitFee}}$


BNum bpow is based on exponentiation by squaring and hold true because (see dapphub dsmath): https://github.com/dapphub/ds-math/blob/e70a364787804c1ded9801ed6c27b440a86ebd32/src/math.sol#L62
```
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
```