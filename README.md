# Ledger Sample

## Description

Sample project demonstrating intercanister calls to the mainnet ICP ledger, written in Motoko for the backend canister and Typescript for the front-end client.
The backend utilizes a lock in a stable map to prevent concurrency issues with double-credits/withdrawals.
The backend canister also maintains its own stable balance of deposits from users so that withdrawals can be tracked properly.

THIS IS A WORK IN PROGRESS.

## Ledger Sample Backend

The main.mo file is the main entry point for a Motoko-based backend application that interacts with the Internet Computer's ledger canister. It provides functionalities for managing and querying account balances, performing transactions, and interacting with the ledger canister.

Key Features

1. Account Management: The application maintains a map of account balances for each principal. It provides functions to get the balance of an account, check the balance of the caller, and get all balances.

2. Transaction Management: The application supports deposit and withdrawal transactions. It maintains a transaction log and a transaction counter. It also provides a function to reclaim ICP.

3. Interactions with Ledger Canister: The application interacts with the ledger canister to perform transactions and query blocks. It also verifies deposits with the ledger.

4. Principal and Account ID Retrieval: The application provides functions to get the principal and account ID of the caller, the installer, and the canister.

5. Concurrency Control: The application uses a lock lookup map to synchronize principal actions against the canister.
Key Data Structures

1. balances: A stable map that stores the balance of each principal.
2. transactionLog: A stable map that stores the transaction log.
3. isAlreadyProcessingLookup_: A map that stores the processing status of each principal.

Key Functions

1. getBalanceByAccount: Gets the balance of an account.
2. deposit_icp: Deposits a given amount of ICP.
3. reclaimICP: Reclaims ICP.
4. notifyDeposit: Notifies the application of a deposit.
5. verifyDepositWithLedger: Verifies a deposit with the ledger canister.
6. get_caller_balance: Gets the balance of the caller.
7. getCanisterBalance: Gets the balance of the canister.
8. getCallerPrincipalAndAccountId: Gets the principal and account ID of the caller.
9. getInstallerPrincipalAndAccountId: Gets the principal and account ID of the installer.
10. getCanisterPrincipalAndAccountId: Gets the principal and account ID of the canister.

Please note that this is a simplified summary and the actual code contains more details and functionalities.

## Package Manager Overview

The project leverages a few package managers:

ICP Canisters:

`dfx` (`dfx.json`) is a multipurpose tool for ICP.  We will primarily use it for canister deployment.

In the `dfx.json` file, the `build` key is set to `npm run deploy`. This instructs the DFINITY Canister SDK
 (`dfx`) to execute the `deploy` script from the `package.json`'s `scripts` section when you run `dfx deploy`.
The `deploy` script is responsible for preparing your project for deployment. It first runs `npm install` to
install all the JavaScript dependencies specified in `package.json`. After the dependencies are installed, it 
executes `npm run build`. This `build` script, defined in `package.json`, triggers `vite build`, which 
compiles, optimizes, and bundles the frontend assets. These assets are then ready to be deployed with the 
`ledger_sample_frontend` canister to the Internet Computer.

For canisters serving front-end assets, the files located in the directory defined by the `source` key in 
`dfx.json` are uploaded as static assets. The `frontend.entrypoint` setting should specify the path to an 
`index.html` file within this `source` directory. In our project, this directory is set to `dist`, meaning that the `index.html` file in the `dist` folder will be used as the entry point for the front-end canister when deployed.  Files in `dist` have been optimized by `vite`.


Backend Motoko:

`vessel` (`vessel.dhall, package-set.dhall`) is a package manager for motoko that helps download the required motoko dependencies such 
as `mo:map/Map`, which we use for stable hashmap support.

Frontend Javascript:

`vite` (`vite.config.js`) will build and optimize the frontend javascript/html assets for fast loading.
The assets are specified in the vite.config.js build.
The build output directory is configured in `vite.config.js` as `outDir: '../../dist'`, which specifies where the production-ready frontend assets will be generated.

`npm` (`package.json`) The `package.json` file serves as the manifest for your JavaScript project. It plays a crucial role in managing the project's dependencies, defining script commands, and storing metadata about the project. Here's a summary of its functionality in the context of this project:

- **Dependency Management**: It lists all the necessary npm packages required for both development and production environments. When you run `npm install`, npm reads this file and installs the versions of the packages specified.

- **Script Shortcuts**: The `scripts` section provides convenient aliases for complex commands. For example, `npm run build` is a shortcut for `vite build`, which compiles your frontend assets for production.

- **Project Configuration**: It can include additional configuration for tools and libraries used in the project, such as Vite, Babel, ESLint, or others.

- **Project Information**: It contains metadata such as the project's name, version, description, repository, license, and author information, which can be important for publishing packages or for documentation purposes.

In this project, `package.json` is configured to work with Vite through the `scripts` section, enabling you to run tasks like building the frontend assets with `npm run build`, which under the hood, calls `vite build`. This integration streamlines your development and build process, ensuring that your frontend assets are prepared correctly for deployment with the `ledger_sample_frontend` canister.

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

[vessel](https://github.com/dfinity/vessel) is a package manager for the Motoko programming language, which is used to develop canisters for the Internet Computer.

On Ubuntu 22.04, use Vessel 0.7.0

On Ubuntu 20.04, use Vessel 0.6.4

Then run `vessel sources`

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

## Deploying to ICP Mainnet

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