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
  var transactionCounter : Nat = 0;

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

  
};
