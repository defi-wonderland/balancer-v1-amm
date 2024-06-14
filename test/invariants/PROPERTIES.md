| Properties                                                                                                  | Type       |
| ----------------------------------------------------------------------------------------------------------- | ---------- |
| BFactory should always be able to deploy new pools                                           | Unit |
| BFactory's blab should always be modifiable by the current blabs                                        | Unit |
| BFactory should always be able to transfer the BToken to the blab, if called by it                                      | Unit |
| BToken increaseApproval should increase the approval of the address by the amount
| BToken decreaseApproval should decrease the approval to max(old-amount, 0) | Unit | 
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
