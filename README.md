## LaunchCrypt smart contract in ethereum

**This repository is responsible for**

-   **Create token**: Follow ERC20 token standard, create new token base on name and ticket. Total supply default to 1 billion.
-   **Create liquidity pairs**: Create a swap pair between new token created and ethereum. The price of token is calculate base on constant product AMM formula.
-   **Token graduation**: After marketcap of a pair reach the limit, user can withdraw all the token they have and a portion of liquidity will be push to uniswap V3.
