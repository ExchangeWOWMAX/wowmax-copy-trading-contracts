# WOWMAX Copy Trading Contracts

## Usage

### Pre Requisites

First, you need to install the dependencies:

```sh
bun install
```

Then, you need to set up all the required
[Hardhat Configuration Variables](https://hardhat.org/hardhat-runner/docs/guides/configuration-variables). You might
also want to install some that are optional.

To assist with the setup process, run `bunx hardhat vars setup`. To set a particular value, such as a BIP-39 mnemonic
variable, execute this:

```sh
bunx hardhat vars set MNEMONIC
? Enter value: ‣ here is where your twelve words mnemonic should be put my friend
```

If you do not already have a mnemonic, you can generate one using this [website](https://iancoleman.io/bip39/).

### Compile

Compile the smart contracts with Hardhat:

```sh
bun run compile
```

### TypeChain

Compile the smart contracts and generate TypeChain bindings:

```sh
bun run typechain
```

### Test

Run the tests with Hardhat:

```sh
bun run test
```

### Lint Solidity

Lint the Solidity code:

```sh
bun run lint:sol
```

### Lint TypeScript

Lint the TypeScript code:

```sh
bun run lint:ts
```

### Coverage

Generate the code coverage report:

```sh
bun run coverage
```

### Report Gas

See the gas usage per unit test and average gas per method call:

```sh
REPORT_GAS=true bun run test
```

### Clean

Delete the smart contract artifacts, the coverage reports and the Hardhat cache:

```sh
bun run clean
```
