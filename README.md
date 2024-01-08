# Ledger Sample

## Description

THIS IS A WORK IN PROGRESS, NOT ALL FUNCTIONALITY IS THERE YET.

The main.mo file appears to be a Motoko module for the DFINITY Internet Computer platform, implementing backend logic for a ledger or wallet service. Here's a summary of its functionality:

- Pre-upgrade Handling: It includes a preupgrade function to save the state of the balances map to a stable variable before a canister upgrade.

- Transaction Management: It defines a TransactionType and TransactionInfo to track deposits and withdrawals, with a stable transactionLog map to record transactions.

- Canister Interfaces: It references mainnet canister IDs for interacting with the ICP ledger and index canisters, and defines functions to interact with these external services, such as retrieving ledger IDs, statuses, balances, and transactions.

- Account and Balance Utilities: It provides utility functions to encode and decode account identifiers, and to retrieve balances and transactions based on account identifiers or principals.

- Balance Operations: It includes functions to get the balance of the caller, installer, and canister, as well as to perform balance checks and retrieve all balances.

- Transaction Counter: It maintains a transactionCounter to assign unique IDs to transactions.

- Concurrency Control: It uses a HashMap to prevent concurrent operations by the same principal with a timeout mechanism.

- Deposit and Withdrawal: It implements functions to deposit and withdraw ICP tokens, including fee handling, transaction verification, and balance updates.

- Error Handling: It has comprehensive error handling for various operations, including ledger interactions and balance checks.

- Verification Functions: It contains functions to verify deposits with the ledger by checking block information and transaction memos.

Overall, the main.mo file is a comprehensive backend module for managing a ledger-like system on the Internet Computer, with a focus on handling ICP token transactions, maintaining balances, and interacting with the ICP ledger and index canisters.

## Installing Frontend Project Dependencies with NPM

Installing node will get you npm.  Best way to install node is to use nvm (node version manager).

## Install nvm
```     
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```
After setting your PATH, install node using nvm:
```
nvm install node
```
Then set the version to use, e.g.,:
```
nvm use v21.4.0
```

Then confirm that both are installed properly by running ```node -v``` and ```npm -v```

Then you can run ```npm install``` to install all dependencies from the package.json

## Building with Vessel (Backend Motoko dependencies)

[Vessel](https://github.com/dfinity/vessel) is a package manager for the Motoko programming language, which is used to develop canisters for the Internet Computer.

On Ubuntu 22.04, use Vessel 0.7.0

On Ubuntu 20.04, use Vessel 0.6.4

Then run 
```
vessel sources
```
To build the motoko dependencies before opening the project in Visual Studio.

## Using Vite for Front End Development

This project utilizes [Vite](https://vitejs.dev/) for an optimized development experience. Vite serves as a build tool that significantly improves the frontend development workflow by providing features like:

- Fast Hot Module Replacement (HMR)
- Out-of-the-box support for TypeScript, JSX, CSS and more
- Efficient bundling for production

To install Vite, run the following from the project directory:
```
npm install vite --save-dev
```
To start the development server with Vite, run:
```
npm run dev
```

This command will compile and bundle your frontend assets quickly, allowing you to see changes in real-time.

For building the production version of your frontend, use:

```
npm run build
```

Vite will create a production-ready bundle in the project root `dist` directory, optimized for the best performance.

Running 
```
dfx deploy --network ic
```
Will deploy the project to mainnet.  Each canister will need about 3T cycles on first deployment.
It runs the build target ```npm run deploy``` defined in the dfx.json, which runs the deploy target
```npm install && npm run build``` in the package.json, and ```npm run build``` runs ```vite build```. 

## Contributing

We welcome contributions to this project. Please see our [Contributing Guide](CONTRIBUTING.md) for more details.

## License

This project is licensed under the [insert license]. See the [LICENSE](LICENSE) file for details.