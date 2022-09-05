# popular shitcoin contract

## overview
This is a complete re-make and not just a code ripoff of the original safe moon contract

There were many things that made the original safe moon contract revolutionary in the shitcoin space (I think they were the first ones to implement the following):
- the ability to take a percentage of the transaction and automatically add it to a locked liquidity pool
- the ability to take a percentage of the transaction and distribute it to all the other token holders

As shady as the intended use it, I found the ability to auto distribute a percentage of the transaction to all the other holders simply amazing so I quickly learned solidity to understand the safe moon contract (the part I was looking for was definitely not logically readable but I re-wrote a readable one for everyone who might be interested).

The solution is actually very clever but very mathematical in which user token balances are not simply numbers in a variable but a computation against a single variable that is being modified on every transaction.

The contract in this folder is the readable version of it, feel free to skim through it so you could understand it yourself.