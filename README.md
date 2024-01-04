# Ledger Sample

## Description

THIS IS A WORK IN PROGRESS, NOT ALL FUNCTIONALITY IS THERE YET.

This Motoko project provides a ledger sample on the Internet Computer. It includes several public functions that allow you to interact with the ledger. Here's an overview of the available public functions:

1. getLedgerId: This function returns the ledger's canister ID.

2. getStatus: This function returns the status of the ledger, including the number of blocks synced.

3. getAccountIdentifierBalance: This function takes an account identifier as input and returns the balance of the account.

4. getAccountIdentifierTransactions: This function takes an object with max_results, start, and account_identifier as input and returns the transactions of the account.

5. getAccountTransactions: This function takes an object with account, start, and max_results as input and returns the transactions of the account.

6. greet: This function takes a name as input and returns a greeting message.

7. getCallerPrincipalAndAccountId: This function returns the caller's principal and account ID.

8. getInstallerPrincipalAndAccountId: This function returns the installer's principal and account ID.

9. getCanisterPrincipalAndAccountId: This function returns the canister's principal and account ID.

10. getBalanceByAccount: This function takes an object with accountIdentifier as input and returns the balance of the account.

11. getBalanceByPrincipal: This function takes an object with principal as input and returns the balance of the account.

12. getCanisterBalance: This function returns the balance of the canister.

13. get_caller_balance: This function takes an object with token as input and returns the balance of the caller.

14. reclaimICP: This function allows the caller to reclaim their ICP.

15. depositICP: This function takes an amount as input and deposits the amount into the caller's account.

16. checkBalance: This function returns the balance of the caller.

17. getAllBalances: This function returns all balances.

Please note that the actual functionality of these functions depends on the implementation in the code.

## Building with Vessel

[Vessel](https://github.com/dfinity/vessel) is a package manager for the Motoko programming language, which is used to develop canisters for the Internet Computer.

On Ubuntu 22.04, use Vessel 0.7.0
On Ubuntu 20.04, use Vessel 0.6.4

Then run 
```
vessel sources
```
To build the dependencies before opening the project in Visual Studio.

Running 
```
dfx deploy --network ic
```
Will deploy the project to mainnet.  Each canister will need about 3T cycles.

## Contributing

We welcome contributions to this project. Please see our [Contributing Guide](CONTRIBUTING.md) for more details.

## License

This project is licensed under the [insert license]. See the [LICENSE](LICENSE) file for details.