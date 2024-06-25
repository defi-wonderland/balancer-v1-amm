# Properties

## Unit

| Tested                              | Property                                                                                                    |
| -                                   | ----------------------------------------------------------------------------------------------------------- |
| [yes](test/unit/BFactory.t.sol:113) | BFactory should always be able to deploy new pools                                                          |
| [yes](test/unit/BFactory.t.sol:139) | BFactory's blab should always be modifiable by the current blabs                                            |
| [yes](test/unit/BFactory.t.sol:198) | BFactory should always be able to transfer the BToken to the blab, if called by it                          |
| [yes](test/unit/BPool.t.sol:1553)   | the amount received can never be less than min amount out                                                   |
| [yes](test/unit/BPool.t.sol:1871)   | the amount spent can never be greater than max amount in                                                    |

## Variable transition

| Tested                           | Property                                                                                                    |
| -                                | ----------------------------------------------------------------------------------------------------------- |
| [yes](test/unit/BToken.t.sol:38) | BToken increaseApproval should increase the approval of the address by the amount                           |
| [yes](test/unit/BToken.t.sol:79) | BToken decreaseApproval should decrease the approval to max(old-amount, 0)                                  |
| [yes](test/unit/BPool.t.sol:850) | total weight can be up to 50e18                                                                             |

## State transition

| Tested                | Property                                                                                                    |
| -                     | ----------------------------------------------------------------------------------------------------------- |
| no                    | a finalized pool cannot switch back to non-finalized                                                        |
| not sure about _only_ | a non-finalized pool can only be finalized when the controller calls finalize()                             |

## Valid state

| Tested | Property                                                                                                    |
| -      | ----------------------------------------------------------------------------------------------------------- |
| no     | a pool can either be finalized or not finalized                                                             |

## High level

| Tested                                                            | Property                                                                                                                |
| -                                                                 | -----------------------------------------------------------------------------------------------------------             |
| no (but we use OZ's ERC20)                                        | BToken should not break the [ToB ERC20 properties](https://github.com/crytic/properties?tab=readme-ov-file#erc20-tests) |
| [yes](test/unit/BPool.t.sol:1675)                                 | an exact amount in should always earn the amount out calculated in bmath                                                |
| [yes](test/unit/BPool.t.sol:2032)                                 | an exact amount out is earned only if the amount in calculated in bmath is transfered                                   |
| no                                                                | there can't be any amount out for a 0 amount in                                                                         |
| no, worth invariant-ing?                                          | the pool btoken can only be minted/burned in the join and exit operations                                               |
| no, worth invariant-ing?                                          | a direct token transfer can never reduce the underlying amount of a given token per BPT                                 |
| [yes](test/unit/BPool.t.sol:2591)                                 | the amount of underlying token when exiting should always be the amount calculated in bmath                             |
| [yes](test/unit/BPool.t.sol:1525)                                 | a swap can only happen when the pool is finalized                                                                       |
| [yes](test/unit/BPool.t.sol:754)                                  | bounding and unbounding token can only be done on a non-finalized pool, by the controller                               |
| [yes](test/unit/BPool.t.sol:781) [yes](test/unit/BPool.t.sol:660) | there always should be between MIN_BOUND_TOKENS and MAX_BOUND_TOKENS bound in a pool                                    |


# Unit for the math libs (BNum and BMath):

## Btoi

btoi should always return the floor(a / BONE) == (a - a%BONE) / BONE

## bfloor

bfloor should always return (a - a % BONE)

## badd 

badd should be commutative
badd should be associative
0 should be identity for badd
badd result should always be gte its terms
badd should never sum terms which have a sum gt uint max
badd should have bsub as reverse operation

## bsub

bsub should not be commutative
bsub should not be associative
bsub should have 0 as identity
bsub result should always be lte its terms
bsub should alway revert if b > a (duplicate with previous tho)

## bsubSign

bsubSign result should always be negative if b > a
bsubSign result should always be positive if a > b
bsubSign result should always be 0 if a == b

## bmul

bmul should be commutative
bmul should be associative
bmul should be distributive
1 should be identity for bmul
0 should be absorbing for mul
bmul result should always be gte a and b

## bdiv

bdiv should be bmul reverse operation // <-- unsolved
1 should be identity for bdiv
bdiv should revert if b is 0 // <-- impl with wrapper to have low lvl call
bdiv result should be lte a

## bpowi

bpowi should return 1 if exp is 0
0 should be absorbing if base
1 should be identity if base
1 should be identity if exp
bpowi should be distributive over mult of the same base x^a * x^b == x^(a+b)
bpowi should be distributive over mult of the same exp  a^x * b^x == (a*b)^x
power of a power should mult the exp (x^a)^b == x^(a*b)

## bpow

bpow should return 1 if exp is 0
0 should be absorbing if base
1 should be identity if base
1 should be identity if exp
bpow should be distributive over mult of the same base x^a * x^b == x^(a+b)
bpow should be distributive over mult of the same exp  a^x * b^x == (a*b)^x
power of a power should mult the exp (x^a)^b == x^(a*b)

## bpowApprox

## calcOutGivenIn

calcOutGivenIn should be inv with calcInGivenOut

calcInGivenOut

## calcPoolOutGivenSingleIn

calcPoolOutGivenSingleIn should be inv with calcSingleInGivenPoolOut

calcSingleInGivenPoolOut

## calcSingleOutGivenPoolIn

calcSingleOutGivenPoolIn should be inv with calcPoolInGivenSingleOut

calcPoolInGivenSingleOut
