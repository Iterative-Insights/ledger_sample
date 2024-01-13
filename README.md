# Ledger Sample

## Description

Sample project demonstrating intercanister calls to the mainnet ICP ledger, written in Motoko for the backend canister and Typescript for the front-end client.  
The backend utilizes a lock in a stable map to prevent concurrency issues with double-credits/withdrawals.
The backend canister also maintains its own stable balance of deposits from users so withdrawals can be tracked properly.

connect2ic is used for multi-wallet support.  If you know a better alternative please reach out to aug@iterative.day

## Getting Started

Follow these instructions to set up the project on mainnet. This guide assumes you are using a Unix-like operating system such as Linux or macOS.

### Prerequisites

- Install [Node.js](https://nodejs.org/) which includes [npm](https://npmjs.com/).
- Install [Vessel](https://github.com/dfinity/vessel) for Motoko package management.
- Install [DFINITY Canister SDK](https://sdk.dfinity.org/docs/quickstart/local-quickstart.html) (`dfx`).

### Installing Node and NPM

1. Install `nvm` (Node Version Manager):
`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash`

2. Install Node.js using `nvm`:
`nvm install node`

3. Set the version of Node.js to use:
`nvm use node`


### Installing Frontend Dependencies
```
cd ledger_sample
npm install
```

### Building with Vessel (Backend Motoko Dependencies)

1. Ensure you have the correct version of Vessel installed for your OS.
2. Run `vessel sources` to fetch the Motoko dependencies.

### Using Vite for Frontend Development

1. Install Vite if it's not already installed:
`npm install vite --save-dev

## Preparing for Deployment

Before deploying to the IC mainnet, it's crucial to run the `dfx generate` command. This command generates the canister interface definitions, which are required for your canisters to interact with each other and with the IC system:

`dfx generate`

Make sure to execute this command after you've made any changes to your canister's interface and before you deploy. This ensures that the latest interface changes are accurately reflected and that your canisters will communicate effectively once deployed to the mainnet.

### Deploying to ICP Mainnet

1. Update the `main.mo` file with your admin principal.
2. [Get free cycles for deployment](https://internetcomputer.org/docs/current/developer-docs/setup/cycles/cycles-faucet)
3. Deploy the project to the Internet Computer mainnet:

`dfx deploy --network ic`

After following these steps, your project should be up and running on ICP mainnet.  [You can also deploy to motoko playground (a quasi testnet) for free without cycles](https://internetcomputer.org/docs/current/developer-docs/setup/playground) but the canisters get automatically removed after 5-10 minutes if not used, which is not good if the canister has ICP deposited.


## Ledger Sample Backend

The main.mo file is the main entry point for a Motoko-based backend application that interacts with the Internet Computer's ledger canister. It provides functionalities for managing and querying account balances, performing transactions, and interacting with the ledger canister.

Please note that this is a simplified summary and the actual code contains more details and functionalities.

Key Features

1. Account Management: The application maintains a map of account balances for each principal. It provides functions to get the balance of an account, check the balance of the caller, and get all balances.

2. Transaction Management: The application supports deposit and withdrawal transactions. It maintains a transaction log. It also provides a function to reclaim ICP to caller, and
an emergency reclaim function for the admin.

3. Interactions with Ledger Canister: The application interacts with the ledger canister to perform transactions and query blocks. It also verifies deposits with the ledger.

4. Principal and Account ID Retrieval: The application provides functions to get the principal and account ID of the caller, the installer, and the canister.

5. Concurrency Control: The application uses a lock lookup map to synchronize principal actions against the canister, and a transaction log to prevent double credits to the balance
map.  The transaction log uses the block height of the transaction as the transaction id.
This is possible as the ICP ledger uses 1 block per transaction.  See https://mmapped.blog/posts/13-icp-ledger#transactions-and-blocks for details.

Key 

Data Structures

1. deposits: A stable map that stores the deposits of each principal.
2. transactionLog: A stable map that stores the transaction log.
3. isAlreadyProcessingLookup_: A map that stores the processing status of each principal.

Key Functions

- getAdminPrincipal: Returns the principal ID of the admin.

- getLedgerId: Fetches the ledger canister ID from the index canister.

- getStatus: Retrieves the status from the index canister.

- getAccountIdentifierBalance: Gets the balance for a given account identifier from the index canister.

- getAccountIdentifierTransactions: Fetches transactions for a given account identifier from the index canister.

- getAccountTransactions: Retrieves transactions for an account from the index canister.

- getCallerPrincipalAndAccountId: Returns the caller's principal and account ID as a text string.

- getInstallerPrincipalAndAccountId: Returns the installer's principal and account ID as a text string.

- getCanisterPrincipalAndAccountId: Returns the canister's principal and account ID as a text string.

- getCanisterAccountId: Returns the canister's account ID as a text string.

- getCanisterPrincipalId: Returns the principal ID of the canister.

- getBalanceByAccount: Returns the balance for a given account identifier.

- getBalanceByPrincipal: Returns the balance for a given principal.

- getCanisterBalance: Returns the balance of the canister.

- get_caller_balance: Returns the balance of the caller for a specified token.

- reclaimICP: Allows the caller to reclaim ICP tokens by transferring them out of the canister.

- checkCallerBalanceInCanister: Checks and returns the balance of the caller within the canister.

- getAllDeposits: Returns all deposit records as an array of tuples containing principals and their respective balances.

- notifyDeposit: Notifies the canister of a deposit and updates the transaction log and balance map accordingly.

- reclaimICPToAdmin: Allows the admin to reclaim all ICP tokens from the canister to the admin's account.

Additionally, there are several private functions and variables:

- isAlreadyProcessingLookup_: A map to track if a principal is already processing an action to prevent concurrent operations.

- isAlreadyProcessingTimeout_: A timeout value to determine how long a principal's action should be locked.

- isAlreadyProcessing_: Checks if a principal is currently processing an action.

- doesTransactionExist: Checks if a transaction with a given ID already exists in the transaction log.

- addTransactionToLog: Adds a transaction to the transaction log.

- verifyDepositWithLedger: Verifies a deposit with the ledger canister by checking the transaction details in a block.

The file also includes several let bindings for constants and actor references, as well as stable var declarations for persistent data like deposits and transactionLog.

## Detailed Instructions and Explanation

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

This project utilizes [Vite](https://vitejs.dev/) for packaging and optimizing the front end assets.

To install Vite, run the following from the project directory:
```
npm install vite --save-dev
```
To start the development server with Vite, run:
```
npm run dev
```

This command will compile and bundle your frontend assets quickly, allowing you to see front end changes in real-time.  The buttons will not work though, only deploying to mainnet
will have working buttons in the front end.

For building the production version of your frontend, use:

```
npm run build
```

Vite will create a production-ready bundle in the project root `dist` directory, optimized for the best performance.

## Deploying to ICP Mainnet
You MUST change the principal in the main.mo to your admin principal which can emergency reclaim ICP deposited to the canister:

```
let adminPrincipal : Principal = Principal.fromText(
    "tyvr4-pols6-lvf2i-j5cp3-k5zs4-gmsp4-r2pvr-teogk-hj3jg-issib-yqe"
  );
```

Running 
```
dfx deploy --network ic
```
Will deploy the project to mainnet.  Each canister will need about 3T cycles on first deployment (allow 7T cycles
to deploy the sample code).
It runs the build target ```npm run deploy``` defined in the dfx.json, which runs the deploy target
```npm install && npm run build``` in the package.json, and ```npm run build``` runs ```vite build```. 

## Contributing

We welcome contributions to this project. Please see our [Contributing Guide](CONTRIBUTING.md) for more details.


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.