import Account "./modules/Account";
import CRC32 "./modules/CRC32";
import Hex "./modules/Hex";
import IndexCanisterInterface "./modules/IndexCanisterInterface";
import LedgerCanisterInterface "./modules/LedgerCanisterInterface";
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

import Map "mo:map/Map";
import { nhash } "mo:map/Map";
import { phash } "mo:map/Map";

// set installer_ Principal when this canister is first installed
shared ({ caller = installer_ }) actor class LedgerSample() = this {
  let adminPrincipal : Principal = Principal.fromText(
    "tyvr4-pols6-lvf2i-j5cp3-k5zs4-gmsp4-r2pvr-teogk-hj3jg-issib-yqe"
  );
  stable var deposits : Map.Map<Principal, Nat64> = Map.new<Principal, Nat64>();

  public shared ({ caller }) func clearAllDeposits() : async Result.Result<Text, Text> {
    if (caller != adminPrincipal) {
      return #err("Unauthorized: Only the admin can call reclaimICPToAdmin.");
    };
    deposits := Map.new<Principal, Nat64>();
    // Optionally, you can return a confirmation message or a result
    return #ok("All deposits have been cleared.");
  };

  type TransactionType = { #Deposit; #Withdrawal };
  type TransactionInfo = { txType : TransactionType; processed : Bool };
  //This map is actually from https://github.com/ZhenyaUsenko/motoko-hash-map
  //and supports stable
  //see https://forum.dfinity.org/t/map-v8-0-0-its-finally-here/18962/21 for details
  //the key is from the transactionId that gets incremented automatically
  //for each new transaction, and is passed to the memo field when calling
  //ledger transfer.  the boolean within TransactionInfo is true if
  //the transaction has been processed in the mainnet ledger
  //a transaction can mean a deposit transaction into the canister, or
  //a withdrawal from the canister
  stable var transactionLog : Map.Map<Nat, TransactionInfo> = Map.new<Nat, TransactionInfo>();

  /** Ids of the mainnet canisters used to create actor supertypes. */
  let CANISTER_IDS = {
    icp_ledger_canister = "ryjl3-tyaaa-aaaaa-aaaba-cai";
    icp_index_canister = "qhbym-qaaaa-aaaaa-aaafq-cai";
  };

  let transferFee : LedgerCanisterInterface.Tokens = { e8s = 10000 };

  let Ledger_ICP : LedgerCanisterInterface.LedgerCanister = actor (CANISTER_IDS.icp_ledger_canister);
  let indexCanister : IndexCanisterInterface.IndexCanister = actor (CANISTER_IDS.icp_index_canister);

  public shared func getAdminPrincipal() : async Principal {
    return adminPrincipal;
  };

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

  public shared ({ caller }) func getCanisterAccountId() : async Text {
    let accountIdentifier = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
    let accountId = Hex.encodeAddress(accountIdentifier);

    return accountId;
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

    if (isAlreadyProcessing_(caller)) {
      return #err("Error: Operation in progress for: " # debug_show (caller));
    };

    let now = Time.now();
    isAlreadyProcessingLookup_.put(caller, now);
    let balance = Map.get(deposits, phash, caller);
    switch (balance) {
      case (?balance) {
        if (balance < transferFee.e8s) {
          isAlreadyProcessingLookup_.delete(caller);
          return #err("Error: Insufficient funds for fee. The balance is only " # debug_show (balance) # " e8s");
        };

        let withdrawAmount = balance - transferFee.e8s;
        //attempt the transfer now
        let res = await Ledger_ICP.transfer({
          memo = 0;
          from_subaccount = null;
          to = Account.accountIdentifier(caller, Account.defaultSubaccount());
          amount = { e8s = withdrawAmount };
          fee = { e8s = transferFee.e8s };
          created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(now)) };
        });
        //handle transfer result
        switch (res) {
          case (#Ok(blockIndex)) {
            Map.set(deposits, phash, caller, 0 : Nat64);
            isAlreadyProcessingLookup_.delete(caller);
            return #ok("Reclaimed: " # debug_show (withdrawAmount) # " e8s ICP for " # Principal.toText(caller) # " in block " # Nat64.toText(blockIndex));
          };
          case (#Err(#InsufficientFunds { balance })) {
            isAlreadyProcessingLookup_.delete(caller);
            return #err("Insufficient funds. The balance is only " # Nat64.toText(balance.e8s) # " e8s");
          };
          case (#Err(other)) {
            isAlreadyProcessingLookup_.delete(caller);
            return #err("Unexpected error: " # debug_show (other));
          };
        };
      };
      case null {
        isAlreadyProcessingLookup_.delete(caller);
        return #err("No balance found for caller: " # Principal.toText(caller));
      };
    };
  };

  public shared ({ caller }) func checkCallerBalanceInCanister() : async Text {
    let balance = Map.get(deposits, phash, caller);
    let balanceText = switch (balance) {
      case (?balance) Nat64.toText(balance);
      case null "0";
    };
    return "Caller's ID: " # Principal.toText(caller) #
    ", Canister's ID: " # Principal.toText(getCanisterPrincipalId()) #
    ", Balance: " # balanceText;
  };

  public query func getAllDeposits() : async [(Principal, Nat64)] {
    let iter = Map.entries(deposits);
    return Iter.toArray(iter);
  };
  
  // Lock lookup map to synchronize Principal actions against the canister
  let isAlreadyProcessingLookup_ : HashMap.HashMap<Principal, Time.Time> = HashMap.HashMap<Principal, Time.Time>(0, Principal.equal, Principal.hash);
  let isAlreadyProcessingTimeout_ : Nat = 600_000_000_000; // "10 minutes ns"

  public query func getIsAlreadyProcessingLookup() : async [(Principal, Time.Time)] {
    let iter = isAlreadyProcessingLookup_.entries();
    return Iter.toArray(iter);
  };

  func isAlreadyProcessing_(caller : Principal) : Bool {
    switch (isAlreadyProcessingLookup_.get(caller)) {
      // No concurrent access of this invoice is taking place.
      case null return false;
      // Parallel access could be occurring, check if enough time
      // has elapsed to automatically release the lock.
      case (?atTime) {
        if ((Time.now() - atTime) >= isAlreadyProcessingTimeout_) {
          // Enough time has elapsed, remove the lock and let the caller proceed.
          isAlreadyProcessingLookup_.delete(caller);
          return false;
        } else {
          // Not enough time has elapsed, let the other caller's processing finish.
          true;
        };
      };
    };
  };

  public shared ({ caller }) func notifyDeposit(
    // transactionId : Nat,
    blockIndex : Nat,
    amount : Nat64,
  ) : async Result.Result<Nat, Text> {
    if (isAlreadyProcessing_(caller)) {
      //we need to retry then
      return #err("isAlreadyProcessing_: " # debug_show (caller));
    } else {
      isAlreadyProcessingLookup_.put(caller, Time.now());
      //use blockIndex as the transactionId
      //in ICP each block contains only 1 transaction.
      //See https://mmapped.blog/posts/13-icp-ledger#transactions-and-blocks
      let transactionId = blockIndex; //can't pass my own memo from wallet transfer, use blockIndex

      if (doesTransactionExist(transactionId)) {
        // A transaction with the same ID already exists, this indicates a double-spending attempt
        //this should not happen now
        isAlreadyProcessingLookup_.delete(caller);
        return #err("A transaction with the same ID already exists,
          indicating a double credit attempt");
      };

      // Add the transaction to the log
      let txInfo : TransactionInfo = { txType = #Deposit; processed = false };
      addTransactionToLog(transactionId, txInfo);

      let memo : Nat64 = Nat64.fromNat(transactionId);
      let verifyResult : Result.Result<Nat, Text> = await verifyDepositWithLedger(
        caller,
        blockIndex,
        amount,
        memo,
      );
      switch (verifyResult) {
        case (#ok(blockIndex)) {
          // Verify the transaction with the ledger canister
          // Update the balance map with the deposit amount
          let currentBalance = Map.get(deposits, phash, (caller));
          let newBalance = switch (currentBalance) {
            case (null) amount; // If currentBalance is null, use amount as the new balance
            case (?balance) balance + amount; // If currentBalance has a value, add amount to it
          };
          Map.set(deposits, phash, caller, newBalance);
          let updatedTxInfo : TransactionInfo = {
            txType = txInfo.txType;
            processed = true;
          };
          addTransactionToLog(transactionId, updatedTxInfo); // Update the transaction log
          isAlreadyProcessingLookup_.delete(caller);
          return #ok(blockIndex);
        };
        case (#err(err)) {
          isAlreadyProcessingLookup_.delete(caller);
          return #err(
            "The transaction could not be verified: " #debug_show (err)
          );
        };
      };
    };
  };

  func doesTransactionExist(transactionId : Nat) : Bool {
    // switch (transactionLog.get(transactionId)) {
    switch (Map.get(transactionLog, nhash, transactionId)) {
      case null { false };
      case _ { true };
    };
  };

  func addTransactionToLog(transactionId : Nat, txInfo : TransactionInfo) : () {
    Map.set(transactionLog, nhash, transactionId, txInfo);
  };

  // returns blockIndex from ledger of confirmed deposit
  func verifyDepositWithLedger(
    caller : Principal,
    blockIndex : Nat,
    amount : Nat64,
    transactionIdNat64 : Nat64,
  ) : async Result.Result<Nat, Text> {
    //Now confirm that the transfer happened by checking the memo in that block
    let queryBlocksResult : Result.Result<Nat, Text> = try {
      let query_blocks_response = await Ledger_ICP.query_blocks({
        start = Nat64.fromNat(blockIndex);
        length = 1;
      });
      let firstBlock = query_blocks_response.blocks[0];

      // let memo = firstBlock.transaction.memo;
      // if (memo != transactionIdNat64) {
      //   return #err(
      //     "transactionId different from memo: " # debug_show (memo) #
      //     " transactionId: " # debug_show (transactionIdNat64)
      //   );
      // };

      let op = firstBlock.transaction.operation;
      switch (op) {
        case (? #Transfer(transferOp)) {
          // Handle Transfer operation here
          // You can access the fields of the transfer operation like this:
          let to = transferOp.to;
          let fee = transferOp.fee;
          let from = transferOp.from; //from is available from query_blocks
          let transferAmount = transferOp.amount;
          // Check if 'to' is the canister id
          let canisterId = Account.accountIdentifier(
            Principal.fromActor(this),
            Account.defaultSubaccount(),
          );

          if (to != Blob.toArray(canisterId)) {
            return #err("Invalid recipient. The 'to' field: " # debug_show (to) # " should be the canister id: " # debug_show (canisterId));
          };
          // Check if fee is 10000
          if (fee != { e8s = transferFee.e8s }) {
            return #err("Invalid fee. The fee should be 10000.");
          };

          //from is the account in a byte array
          let accountIdentifier = Account.accountIdentifier(caller, Account.defaultSubaccount());
          // Check if 'from' is the caller
          // if (from != Blob.toArray(Principal.toBlob(caller))) {
          if (from != Blob.toArray(accountIdentifier)) {
            return #err("Invalid sender. The 'from' field: " # debug_show (from) # " should be the caller: " # debug_show (caller));
          };

          // Check if 'amount' is the same as the amount passed in
          if (transferAmount.e8s != amount) {
            return #err("Invalid amount. The 'amount' being verified should be the same as the amount in the ledger.");
          };
          //if all checks pass, return the blockIndex of the confirmed deposit
          return #ok(blockIndex);
        };
        // case (?#Approve op) { return #err("Operation is Approve"); }; /* handle Approve operation */ };
        case _ return #err("Unexpected operation type: " # debug_show (op)); // handle all other operations
      };
    } catch e {
      return #err("Query blocks failed for reason:\n" # Error.message(e));
    };
  };

  public shared ({ caller }) func reclaimICPToAdmin() : async Result.Result<Text, Text> {
    if (caller != adminPrincipal) {
      return #err("Unauthorized: Only the admin can call reclaimICPToAdmin.");
    };

    let canisterAccountId = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
    let adminAccountIdentifier = Account.accountIdentifier(adminPrincipal, Account.defaultSubaccount());

    let canisterBalanceResult = await Ledger_ICP.account_balance({
      account = canisterAccountId;
    });

    switch (canisterBalanceResult) {
      case (balance) {
        if (balance.e8s <= transferFee.e8s) {
          return #err("Insufficient funds to cover the transfer fee.");
        };
        let reclaimAmount = balance.e8s - transferFee.e8s;
        let transferResult = await Ledger_ICP.transfer({
          memo = 0;
          from_subaccount = null;
          to = adminAccountIdentifier;
          amount = { e8s = reclaimAmount };
          fee = transferFee;
          created_at_time = null;
        });
        switch (transferResult) {
          case (#Ok(blockIndex)) {
            return #ok("ICP reclaimed to admin account in block " # Nat64.toText(blockIndex));
          };
          case (#Err(e)) {
            return #err("Transfer failed: " # debug_show (e));
          };
        };
      };
    };
  };

};
