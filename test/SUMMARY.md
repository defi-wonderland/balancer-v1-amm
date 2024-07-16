# Tests Summary

There are 9 solidity files, totalling 939 sloc.

| filename                      | language | code | comment | blank | total |
| :---------------------------- | :------- | :--- | :------ | :---- | :---- |
| src/contracts/BCoWConst.sol   | solidity | 4    | 10      | 2     | 16    |
| src/contracts/BCoWFactory.sol | solidity | 20   | 13      | 7     | 40    |
| src/contracts/BCoWPool.sol    | solidity | 90   | 41      | 24    | 155   |
| src/contracts/BConst.sol      | solidity | 23   | 29      | 9     | 61    |
| src/contracts/BFactory.sol    | solidity | 44   | 17      | 11    | 72    |
| src/contracts/BMath.sol       | solidity | 128  | 156     | 18    | 302   |
| src/contracts/BNum.sol        | solidity | 133  | 40      | 28    | 201   |
| src/contracts/BPool.sol       | solidity | 473  | 104     | 107   | 684   |
| src/contracts/BToken.sol      | solidity | 24   | 27      | 7     | 58    |


## Interdependencies
BCoWFactory deploys a bcowpool
BCoWPool is a bpool which adds signature validation
Factory deploys a pool and can "collect" from the pool
Pool inherit btoken (which represents a LP) and bmath
Bmath uses bnum

# Unit tests
Current coverage is XXX % for the 9 contracts, accross XXX tests. All tests are passing. Unit tests are writtent using the branched-tree technique and Bulloak as templating tool.

< TABLE >

# Integration tests

# Property tests
We identified 24 properties. We challenged these either in a long-running fuzzing campaign (targeting 23 of these in XXX runs) or via symbolic execution (for 8 properties).

## Fuzzing campaign

We used echidna to test these 23 properties. In addition to these, another fuzzing campaign as been led against the mathematical contracts (BNum and BMath), insuring the operation properties were holding.

Limitations/future improvements
Currently, the swap logic are tested against the swap in/out functions (and, in a similar way, liquidity management via the join/exit function). The combined equivalent (joinswapExternAmountIn, joinswapPoolAmountOut, etc) should be tested too.

## Formal verification: Symbolic Execution
We managed to test 10 properties out of the 23. Properties not tested are either not easily challenged with symbolic execution (statefullness needed) or limited by Halmos itself (hitting loops in the implementation for instance).

Additional properties from BNum were tested independently too (with severe limitations due to loop unrolling boundaries).


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