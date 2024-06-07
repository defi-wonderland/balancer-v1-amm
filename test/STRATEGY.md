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