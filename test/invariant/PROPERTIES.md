| Properties                                                                                                  | Type       |
| ----------------------------------------------------------------------------------------------------------- | ---------- |
| BFactory should always be able to deploy new pools                                           | Unit |
| BFactory's blab should always be modifiable by the current blabs                                        | Unit |
| BFactory should always be able to transfer the BToken to the blab, if called by it                                      | Unit |
| BToken increaseApproval should increase the approval of the address by the amount | Variable transition |
| BToken decreaseApproval should decrease the approval to max(old-amount, 0) | Variable transition | 
| BToken should not break the ToB ERC20 properties (https://github.com/crytic/properties?tab=readme-ov-file#erc20-tests) | High level | 
| an exact amount in should always earn the amount out calculated in bmath | High level  | 
| an exact amount out is earned only if the amount in calculated in bmath is transfered | High level  | 
| there can't be any amount out for a 0 amount in | High level | 
| the amount received can never be less than min amount out | Unit | 
| the amount spent can never be greater than max amount in | Unit | 
| the pool btoken can only be minted/burned in the join and exit operations | High level  | 
| a direct token transfer can never reduce the underlying amount of a given token per BPT | High level | 
| the amount of underlying token when exiting should always be the amount calculated in bmath | High level | 
| a pool can either be finalized or not finalized | Valid state | 
| a finalized pool cannot switch back to non-finalized | State transition | 
| a non-finalized pool can only be finalized when the controller calls finalize() | State transition | 
| a swap can only happen when the pool is finalized | High level |
| bounding and unbounding token can only be done on a non-finalized pool, by the controller | High level  | 
| there always should be between MIN_BOUND_TOKENS and MAX_BOUND_TOKENS bound in a pool | High level | 
| total weight can be up to 50e18 | Variable transition | 


Unit for the math libs (BNum and BMath):

btoi should always return the floor(a / BONE) == (a - a%BONE) / BONE
bfloor should always return (a - a % BONE)
badd should be commutative
badd should be associative
0 should be identity for badd
badd result should always be gte its terms
badd should never sum terms which have a sum gt uint max
badd should have bsub as reverse operation

bsub should not be commutative
bsub should not be associative
bsub should have 0 as identity
bsub result should always be lte its terms
bsub should alway revert if b > a (duplicate with previous tho)

bsubSign result should always be negative if b > a
bsubSign result should always be positive if a > b
bsubSign result should always be 0 if a == b

bmul should be commutative
bmul should be associative
bmul should be distributive
1 should be identity for bmul
0 should be absorbing for mul
bmul result should always be gte a and b

bdiv should be bmul reverse operation // <-- unsolved
1 should be identity for bdiv
bdiv should revert if b is 0 // <-- impl with wrapper to have low lvl call
bdiv result should be lte a

bpowi should return 1 if exp is 0
0 should be absorbing if base
1 should be identity if base
1 should be identity if exp
bpowi should be distributive over mult of the same base x^a * x^b == x^(a+b)
bpowi should be distributive over mult of the same exp  a^x * b^x == (a*b)^x
power of a power should mult the exp (x^a)^b == x^(a*b)

bpow should return 1 if exp is 0
0 should be absorbing if base
1 should be identity if base
1 should be identity if exp
bpow should be distributive over mult of the same base x^a * x^b == x^(a+b)
bpow should be distributive over mult of the same exp  a^x * b^x == (a*b)^x
power of a power should mult the exp (x^a)^b == x^(a*b)


bpowApprox

calcOutGivenIn

calcOutGivenIn should be inv with calcInGivenOut

calcInGivenOut

calcPoolOutGivenSingleIn

calcPoolOutGivenSingleIn should be inv with calcSingleInGivenPoolOut

calcSingleInGivenPoolOut

calcSingleOutGivenPoolIn

calcSingleOutGivenPoolIn should be inv with calcPoolInGivenSingleOut

calcPoolInGivenSingleOut