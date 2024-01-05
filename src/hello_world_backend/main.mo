import Account "./modules/Account";
import CRC32 "./modules/CRC32";
import Hex "./modules/Hex";
import IndexCanisterInterface "./modules/IndexCanisterInterface";
import SupportedToken "./modules/supported-token/SupportedToken";
import Types "./modules/Types";

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

import Source "mo:ulid/Source";
import ULID "mo:ulid/ULID";
import XorShift "mo:rand/XorShift";

// set installer_ Principal when this canister is first installed
shared ({ caller = installer_ }) actor class LedgerSample() = this {
  stable var balancesStable : [(Principal, Nat64)] = [];
  // Convert stable variable to HashMap on actor initialization
  let balances : HashMap.HashMap<Principal, Nat64> = HashMap.fromIter<Principal, Nat64>(
    Iter.fromArray(balancesStable),
    balancesStable.size(),
    Principal.equal,
    Principal.hash,
  );
  /** Compulsory constants this canister must adhere to. */

  system func preupgrade() {
    let iter = balances.entries();
    balancesStable := Iter.toArray(iter);
  };

  module MagicNumbers {
    // Invoice Canister Constraints:
    public let SMALL_CONTENT_SIZE = 256;
    public let LARGE_CONTENT_SIZE = 32_000;
    public let MAX_INVOICES = 30_000;
    public let MAX_INVOICE_CREATORS = 256;
  };

  /** Ids of the mainnet canisters used to create actor supertypes. */
  let CANISTER_IDS = {
    icp_ledger_canister = "ryjl3-tyaaa-aaaaa-aaaba-cai";
    icp_index_canister = "qhbym-qaaaa-aaaaa-aaafq-cai";
  };

  // Invoice canister only uses transfer and balance methods of ledger canisters; these are those supertypes:
  let Ledger_ICP : SupportedToken.Actor_Supertype_ICP = actor (CANISTER_IDS.icp_ledger_canister);

  let indexCanister : IndexCanisterInterface.IndexCanister = actor (CANISTER_IDS.icp_index_canister);

  public shared func getLedgerId() : async Principal {
    return await indexCanister.ledger_id();
  };

  public shared func getStatus() : async IndexCanisterInterface.Status {
    return await indexCanister.status();
  };

  public shared func getAccountIdentifierBalance(accountIdentifier : Text) : async Nat64 {
    return await indexCanister.get_account_identifier_balance(accountIdentifier);
  };

  public shared func getAccountIdentifierTransactions(args : IndexCanisterInterface.GetAccountIdentifierTransactionsArgs) : async IndexCanisterInterface.GetAccountIdentifierTransactionsResult {
    return await indexCanister.get_account_identifier_transactions(args);
  };

  public shared func getAccountTransactions(args : IndexCanisterInterface.GetAccountTransactionsArgs) : async IndexCanisterInterface.GetAccountIdentifierTransactionsResult {
    return await indexCanister.get_account_transactions(args);
  };

  /// Account Identitier type.
  public type AccountIdentifier = {
    hash : [Nat8];
  };

  private let symbols = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];

  private let base : Nat8 = 0x10;

  public shared ({ caller }) func getCallerPrincipalAndAccountId() : async Text {
    let principal = Principal.toText(caller);
    let accountIdentifier = Account.accountIdentifier(caller, Account.defaultSubaccount());
    let accountId = Hex.encodeAddress(accountIdentifier);

    return "Caller's Principal: " # principal # ", Account ID: " # accountId;
  };

  public shared ({ caller }) func getInstallerPrincipalAndAccountId() : async Text {
    let principal = Principal.toText(installer_);
    let accountIdentifier = Account.accountIdentifier(caller, Account.defaultSubaccount());
    let accountId = Hex.encodeAddress(accountIdentifier);

    return "installer_'s Principal: " # principal # ", Account ID: " # accountId;
  };

  public shared ({ caller }) func getCanisterPrincipalAndAccountId() : async Text {
    let principal = Principal.toText(Principal.fromActor(this));
    let accountIdentifier = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
    let accountId = Hex.encodeAddress(accountIdentifier);

    return "Canister's Principal: " # principal # ", Account ID: " # accountId;
  };

  func getCanisterPrincipalId() : Principal {
    return Principal.fromActor(this);
  };

  public shared ({ caller }) func getBalanceByAccount(
    { accountIdentifier } : {
      accountIdentifier : Text;
    }
  ) : async Types.GetCallerBalanceResult {
    try {
      // let accountToCheck = Account.accountIdentifier(accountIdentifier, Account.defaultSubaccount());
      let balance = #ICP(await Ledger_ICP.account_balance({ account = Hex.decode(accountIdentifier) }));
      #ok({ balance });
    } catch e {
      #err({ kind = #CaughtException(Error.message(e)) });
    };
  };

  public shared ({ caller }) func getBalanceByPrincipal(
    { principal } : {
      principal : Text;
    }
  ) : async Types.GetCallerBalanceResult {
    try {
      let accountToCheck = Account.accountIdentifier(Principal.fromText(principal), Account.defaultSubaccount());
      let balance = #ICP(await Ledger_ICP.account_balance({ account = accountToCheck }));
      #ok({ balance });
    } catch e {
      #err({ kind = #CaughtException(Error.message(e)) });
    };
  };

  public shared ({ caller }) func getCanisterBalance() : async Types.GetCallerBalanceResult {
    try {
      let canisterAccountId = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
      let balance = #ICP(await Ledger_ICP.account_balance({ account = canisterAccountId }));
      #ok({ balance });
    } catch e {
      #err({ kind = #CaughtException(Error.message(e)) });
    };
  };

  public shared ({ caller }) func get_caller_balance(
    { token } : Types.GetCallerBalanceArgs
  ) : async Types.GetCallerBalanceResult {
    let subaccountAddress : SupportedToken.Address = SupportedToken.getCreatorSubaccountAddress({
      token;
      creator = caller;
      canisterId = getCanisterPrincipalId();
    });
    // Query the corresponding token-ledger canister, wrapping the actual async call with
    // a try/catch to proactively handle the many ways things could go wrong.
    try {
      // SupportedToken.Address is a variant with its tag the name of the token,
      // and its argument the specific address type of that token. Switch on it
      // to unwrap that specific address argument from the tag.
      // The balance is returned to the caller as it is from the token-canister ledger
      // (without the #Ok, since the invoice canister is returning it instead).
      // For example, for a caller querying their ICP creator subaccount balance,
      // they'd get #ok(#ICP{ balance = { e8s = 10000000s }}).
      switch subaccountAddress {
        case (#ICP accountIdentifier) {
          let balance = #ICP(await Ledger_ICP.account_balance({ account = accountIdentifier }));
          #ok({ balance });
        };
      };
    } catch e {
      // If the inter-canister call failed, return the error's literal message.
      #err({ kind = #CaughtException(Error.message(e)) });
    };
  };

  public shared ({ caller }) func reclaimICP() : async Result.Result<Text, Text> {
    let fee : Nat64 = 10_000;
    let now = Time.now();
    switch (balances.get(caller)) {
      case (?balance) {
        if (balance < fee) {
          return #err("Insufficient funds for fee. The balance is only " # Nat64.toText(balance) # " e8s");
        };
        let amount = balance - fee;
        let res = await Ledger_ICP.transfer({
          memo = 0;
          from_subaccount = null;
          to = Account.accountIdentifier(caller, Account.defaultSubaccount());
          amount = { e8s = amount };
          fee = { e8s = fee };
          created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(now)) };
        });
        switch (res) {
          case (#Ok(blockIndex)) {
            balances.put(caller, 0);
            return #ok("Sent ICP to " # Principal.toText(caller) # " in block " # Nat64.toText(blockIndex));
          };
          case (#Err(#InsufficientFunds { balance })) {
            return #err("Insufficient funds. The balance is only " # Nat64.toText(balance.e8s) # " e8s");
          };
          case (#Err(other)) {
            return #err("Unexpected error: " # debug_show (other));
          };
        };
      };
      case null {
        return #err("No balance found for caller: " # Principal.toText(caller));
      };
    };
  };

  public shared ({ caller }) func checkCallerBalanceInCanister() : async Text {
    let balance = switch (balances.get(caller)) {
      case (?balance) Nat64.toText(balance);
      case null "0";
    };
    return "Caller's ID: " # Principal.toText(caller) # ", Canister's ID: " # Principal.toText(getCanisterPrincipalId()) # ", Balance: " # balance;
  };

  public query func getAllBalances() : async [(Principal, Nat64)] {
    let iter = balances.entries();
    return Iter.toArray(iter);
  };

  // Change the key of the map to be a tuple of the principal and the block index
  let pendingDeposits = TrieMap.TrieMap<Principal, [Nat]>(Principal.equal, Principal.hash);
  stable var transactionCounter : Nat = 0;
  
  func incTransactionCounter() : Nat {
    transactionCounter += 1;
    return transactionCounter;
  };

  /** Lock lookup map to synchronize invoice's verification and subaccount balance
    recovery by invoice id. To prevent edge cases of lock not being released due to
    unforeseen bug in this canister's code, if the elapsed time between locking the
    same invoice id is greater than the `isAlreadyProcessingTimeout_` the lock will
    automatically be released (see `isAlreadyProcessing_` method below).
    _Note the tuple with `Principal` is used in case developer would need to inspect
    who's been calling._  */
  let isAlreadyProcessingLookup_ = HashMap.HashMap<Text, (Time.Time, Principal)>(32, Text.equal, Text.hash);
  let isAlreadyProcessingTimeout_ : Nat = 600_000_000_000; // "10 minutes ns"

  /** Checks whether the invoice of the given id is already in the process of being verified or
    having its subaccount balance recovered. Automatically removes any lock if enough time has
    passed between checks for the same id.  */
  func isAlreadingProcessing_(id : Types.InvoiceId, caller : Principal) : Bool {
    switch (isAlreadyProcessingLookup_.get(id)) {
      // No concurrent access of this invoice is taking place.
      case null return false;
      // Parallel access could be occurring, check if enough time
      // has elapsed to automatically release the lock.
      case (?(atTime, who)) {
        if ((Time.now() - atTime) >= isAlreadyProcessingTimeout_) {
          // Enough time has elapsed, remove the lock and let the caller proceed.
          isAlreadyProcessingLookup_.delete(id);
          return false;
        } else {
          // Not enough time has elapsed, let the other caller's processing finish.
          true;
        };
      };
    };
  };

/**
This function deposits the given amount of ICP while checking isAlreadingProcessing_.
If there is no already processing transaction, then it will create a lock entry
in isAlreadyProcessingLookup_
It will pass a unique transaction id to the memo of the ledger transfer function,
and transfer the ICP to the canisters account 
**/
  // public shared ({ caller }) func deposit_icp(
  //   { amount; } : Types.DepositICPArgs
  // ) : async Types.DepositICPResult {

  //   let transactionId = incTransactionCounter();
  //   if (isAlreadingProcessing_(transactionId, caller)) {
  //     return #err({ kind = #InProgress });
  //   };
  //   isAlreadyProcessingLookup_.put(transactionId, (Time.now(), caller));
  //   let canisterPrincipal = Principal.fromActor(this); // Get the canister's principal
  //   let canisterAccountIdentifier = Account.accountIdentifier(canisterPrincipal, Account.defaultSubaccount()); // Convert the canister's principal to an account identifier

  //   let transferResult : Result.Result<Nat, Text> = try {
  //     await Ledger_ICP.transfer({
  //       to = canisterAccountIdentifier;
  //       amount = amount;
  //       fee = 10000;
  //       memo = Nat64.fromNat(transactionId);
  //       from_subaccount = null;
  //       created_at_time = Time.now();
  //     });
  //     #ok(transactionId);
  //   } catch e {
  //     #err("Transfer failed for reason:\n" # Error.message(e));
  //   };
  //   let queryBlocksResult : Result.Result<Nat, Text> = try {
  //     let blocks = await Ledger_ICP.query_blocks({
  //       start = Nat64.fromNat(transactionId);
  //       count = 1;
  //     });
  //     switch (blocks) {
  //       case ([]): #err("No blocks found for transaction");
  //       case (block :: ) {
  //         switch (block.transactions) {
  //           case ([]): #err("No transactions found in block");
  //           case (transaction :: _) {
  //             if (transaction.from == caller &&
  //                 transaction.to == getCanisterPrincipalAndAccountId().accountIdentifier &&
  //                 transaction.memo == Nat64.fromNat(transactionId)) {
  //               #ok(transactionId);
  //             } else {
  //               #err("Transaction details do not match");
  //             };
  //           };
  //         };
  //       };
  //     };
  //   } catch e {
  //     #err("Query blocks failed for reason:\n" # Error.message(e));
  //   };
  //   isAlreadyProcessingLookup_.delete(transactionId);
  //   return transferResult;
  // };




  /****Recovers funds from an invoice subaccount for the given invoice id.**
      This method can be used to refund partial payments of an invoice not yet successfully
    verified paid or transfer funds out from an invoice subaccount already successfully
    verified if they are mistakenly sent after or in addition to the amount already paid.
    In either case the total balance of the subaccount will be transferred to the given
    destination (less the cost a transfer fee); the associated invoice record will not be
    changed in any way so this is **not** a means to refund an invoice that's already been
    successfully verified paid (as those proceeds have already been sent  to its creator's
    subaccount as a result of successful  verification).
      The given destination can either be an address or its text encoded equivalent provided
    the text is valid as acceptable address input matching the token type of the invoice for
    the given id.
      The process of recovering an invoice's subaccount balance is synchronized by locking
    to the invoice's id to prevent conflicts in the event of multiple calls trying to either
    recover the balance of or verify the same invoice at the same time; however this lock
    will automatically be released if enough time has elapsed between calls.
    _Only authorized for the invoice's creator and those on the invoice's verify permission list._  */
  
  // public shared ({ caller }) func recover_invoice_subaccount_balance(
  //   { id; destination } : Types.RecoverInvoiceSubaccountBalanceArgs
  // ) : async Types.RecoverInvoiceSubaccountBalanceResult {

  //   let { token; creator } = invoice;
  //   switch (SupportedToken.getAddressOrUnitErr(token, destination)) {
  //     case (#err) return #err({ kind = #InvalidDestination });
  //     case (#ok destinationAddress) {
  //       if (isAlreadingProcessing_(id, caller)) {
  //         return #err({ kind = #InProgress });
  //       };
  //       isAlreadyProcessingLookup_.put(id, (Time.now(), caller));
  //       let invoiceSubaccountAddress = SupportedToken.getInvoiceSubaccountAddress({
  //         token;
  //         id;
  //         creator;
  //         canisterId = getInvoiceCanisterId_();
  //       });
  //       let balanceCallResponse : Result.Result<Nat, Text> = try {
  //         switch invoiceSubaccountAddress {
  //           case (#ICP accountIdentifier) {
  //             let { e8s } = await Ledger_ICP.account_balance({
  //               account = accountIdentifier;
  //             });
  //             #ok(Nat64.toNat(e8s));
  //           };
  //           case (#ICRC1 account) #ok(await Ledger_ICRC1.icrc1_balance_of(account));
  //         };
  //       } catch e {
  //         #err("Balance call failed for reason:\n" # Error.message(e));
  //       };
  //       switch balanceCallResponse {
  //         case (#err err) {
  //           isAlreadyProcessingLookup_.delete(id);
  //           #err({ kind = #CaughtException(err) });
  //         };
  //         case (#ok currentBalance) {
  //           if (currentBalance == 0) {
  //             isAlreadyProcessingLookup_.delete(id);
  //             return #err({ kind = #NoBalance });
  //           } else {
  //             let fee = SupportedToken.getTransactionFee(token);
  //             // Verify amount to transfer is enough not to trap covering the
  //             // transfer fee and ending up transferring at least one token.
  //             if (currentBalance <= fee) {
  //               isAlreadyProcessingLookup_.delete(id);
  //               return #err({ kind = #InsufficientTransferAmount });
  //             } else {
  //               let stTransferArgs = SupportedToken.getTransferArgsFromInvoiceSubaccount({
  //                 id;
  //                 creator;
  //                 amountLessTheFee = (currentBalance - fee);
  //                 fee;
  //                 to = destinationAddress;
  //               });
  //               let transferCallResponse : Result.Result<SupportedToken.TransferResult, Text> = try {
  //                 switch stTransferArgs {
  //                   case (#ICP transferArgs) {
  //                     let transferResult = await Ledger_ICP.transfer(getInvoiceCanisterId_(), transferArgs);
  //                     #ok(#ICP(transferResult));
  //                   };
  //                   case (#ICRC1 transferArgs) {
  //                     let transferResult = await Ledger_ICRC1.icrc1_transfer(getInvoiceCanisterId_(), transferArgs);
  //                     #ok(#ICRC1(transferResult));
  //                   };
  //                 };
  //               } catch e {
  //                 #err("Transfer call failed for reason:\n" # Error.message(e));
  //               };
  //               switch transferCallResponse {
  //                 case (#err errMsg) {
  //                   isAlreadyProcessingLookup_.delete(id);
  //                   #err({ kind = #CaughtException(errMsg) });
  //                 };
  //                 case (#ok stTransferResult) {
  //                   switch (SupportedToken.rewrapTransferResults(stTransferResult)) {
  //                     case (#ok transferSuccess) {
  //                       let balanceRecovered = SupportedToken.wrapAsTokenAmount(token, currentBalance - fee);
  //                       isAlreadyProcessingLookup_.delete(id);
  //                       #ok({ transferSuccess; balanceRecovered });
  //                     };
  //                     case (#err transferErr) {
  //                       isAlreadyProcessingLookup_.delete(id);
  //                       #err({
  //                         kind = #SupportedTokenTransferErr(transferErr);
  //                       });
  //                     };
  //                   };
  //                 };
  //               };
  //             };
  //           };
  //         };
  //       };
  //     };
  //   };

  // };

};
