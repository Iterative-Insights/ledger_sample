import Array "mo:base/Array";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import XorShift "mo:rand/XorShift";
import Source "mo:ulid/Source";
import ULID "mo:ulid/ULID";
import Nat8 "mo:base/Nat8";
import Char "mo:base/Char";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Int "mo:base/Int";

import SupportedToken "./modules/supported-token/SupportedToken";
import Types "./modules/Types";
import Account "./modules/Account";
import Hex "./modules/Hex";
import CRC32 "./modules/CRC32";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

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

  /** Ids of the token ledger canisters used to create actor supertypes. */
  let CANISTER_IDS = {
    icp_ledger_canister = "ryjl3-tyaaa-aaaaa-aaaba-cai";
    icp_index_canister = "qhbym-qaaaa-aaaaa-aaafq-cai";
  };

  // Invoice canister only uses transfer and balance methods of ledger canisters; these are those supertypes:
  let Ledger_ICP : SupportedToken.Actor_Supertype_ICP = actor (CANISTER_IDS.icp_ledger_canister);

  type Time = Nat64;
  type ICPTs = Nat64;
  type Subaccount = Blob;
  type Memo = Nat64;
  type BlockHeight = Nat64;

  type TransactionError = { #error : Text };

  // type Transaction = {
  //   to : Principal;
  //   fee : ICPTs;
  //   from : Principal;
  //   memo : Memo;
  //   amount : ICPTs;
  //   time : Time;
  //   from_subaccount : Subaccount;
  //   to_subaccount : Subaccount;
  // };

  type Tokens = { e8s : Nat64 };

  type Operation = {
    #Approve : {
      fee : Tokens;
      from : Text;
      allowance : Tokens;
      expires_at : ?{ timestamp_nanos : Nat64 };
      spender : Text;
    };
    #Burn : { from : Text; amount : Tokens };
    #Mint : { to : Text; amount : Tokens };
    #Transfer : { to : Text; fee : Tokens; from : Text; amount : Tokens };
    #TransferFrom : {
      to : Text;
      fee : Tokens;
      from : Text;
      amount : Tokens;
      spender : Text;
    };
  };

  type Transaction = {
    memo : Nat64;
    icrc1_memo : ?[Nat8];
    operation : Operation;
    created_at_time : ?{ timestamp_nanos : Nat64 };
  };

  type GetTransactionsResponse = {
    #ok : { transactions : [Transaction]; has_more : Bool };
    #error : TransactionError;
  };

  type TransactionWithId = { id : Nat64; transaction : Transaction };

  type GetAccountIdentifierTransactionsResponse = {
    balance : Nat64;
    transactions : [TransactionWithId];
    oldest_tx_id : ?Nat64;
  };

  type GetAccountIdentifierTransactionsError = { message : Text };

  type GetAccountIdentifierTransactionsArgs = {
    max_results : Nat64;
    start : ?Nat64;
    account_identifier : Text;
  };

  type GetAccountIdentifierTransactionsResult = {
    #Ok : GetAccountIdentifierTransactionsResponse;
    #Err : GetAccountIdentifierTransactionsError;
  };

  type Account = { owner : Principal; subaccount : ?[Nat8] };

  type GetAccountTransactionsArgs = {
    account : Account;
    // The txid of the last transaction seen by the client.
    // If None then the results will start from the most recent
    // txid.
    start : ?Nat;
    // Maximum number of transactions to fetch.
    max_results : Nat;
  };

  type GetBlocksRequest = { start : Nat; length : Nat };

  type GetBlocksResponse = { blocks : [[Nat8]]; chain_length : Nat64 };

  type Status = { num_blocks_synced : Nat64 };

  type IndexCanister = actor {
    // getTransactions : shared (Principal, BlockHeight) -> async GetTransactionsResponse;
    get_account_identifier_balance : shared (text : Text) -> async Nat64;
    get_account_identifier_transactions : shared (args : GetAccountIdentifierTransactionsArgs) -> async GetAccountIdentifierTransactionsResult;
    get_account_transactions : shared (args : GetAccountTransactionsArgs) -> async GetAccountIdentifierTransactionsResult;
    get_blocks : shared (request : GetBlocksRequest) -> async GetBlocksResponse;
    // http_request : shared (request : HttpRequest) -> async HttpResponse;
    ledger_id : shared () -> async Principal;
    status : shared () -> async Status;
    icrc1_balance_of : shared (account : Account) -> async Nat64;
  };

  let indexCanister : IndexCanister = actor (CANISTER_IDS.icp_index_canister);

  public shared func getLedgerId() : async Principal {
    return await indexCanister.ledger_id();
  };

  public shared func getStatus() : async Status {
    return await indexCanister.status();
  };

  public shared func getAccountIdentifierBalance(accountIdentifier : Text) : async Nat64 {
    return await indexCanister.get_account_identifier_balance(accountIdentifier);
  };

  public shared func getAccountIdentifierTransactions(args : GetAccountIdentifierTransactionsArgs) : async GetAccountIdentifierTransactionsResult {
    return await indexCanister.get_account_identifier_transactions(args);
  };

  public shared func getAccountTransactions(args : GetAccountTransactionsArgs) : async GetAccountIdentifierTransactionsResult {
    return await indexCanister.get_account_transactions(args);
  };

  /// Account Identitier type.
  public type AccountIdentifier = {
    hash : [Nat8];
  };

  /// Convert bytes array to hex string.
  /// E.g `[255,255]` to "ffff"
  func encode(array : [Nat8]) : Text {
    Array.foldLeft<Nat8, Text>(
      array,
      "",
      func(accum, u8) {
        accum # nat8ToText(u8);
      },
    );
  };

  private let symbols = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
  ];

  private let base : Nat8 = 0x10;
  /// Convert a byte to hex string.
  /// E.g `255` to "ff"
  func nat8ToText(u8 : Nat8) : Text {
    let c1 = symbols[Nat8.toNat((u8 / base))];
    let c2 = symbols[Nat8.toNat((u8 % base))];
    return Char.toText(c1) # Char.toText(c2);
  };  

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

  // // Returns the default account identifier of this canister.
  // public func getCanisterAccountId() : async Text {
  //   let accountIdentifier = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
  //   Hex.encodeAddress(accountIdentifier);
  // };

  /// Return the Text of the account identifier.
  func accountToText(p : AccountIdentifier) : Text {
    let crc = CRC32.crc32(p.hash);
    let buffer = Buffer.Buffer<Nat8>(32);
    buffer.append(Buffer.fromArray(crc));
    buffer.append(Buffer.fromArray(p.hash));

    // let aid_bytes = Array.append<Nat8>(crc, p.hash);
    let aid_bytes = Buffer.toArray(buffer);

    return encode(aid_bytes);
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

  public shared ({ caller }) func depositICP(amount : Nat64) : async () {
    // Subtract the amount from the sender's balance
    let senderBalance = switch (balances.get(caller)) {
      case (?balance) balance;
      case null (0 : Nat64);
    };
    assert (senderBalance >= amount);
    balances.put(caller, senderBalance - amount);

    // Add the amount to the canister's balance
    let canisterPrincipal = Principal.fromActor(this);
    let canisterBalance = switch(balances.get(canisterPrincipal)) {
      case (?balance) balance;
      case null (0 : Nat64);
    };
    balances.put(canisterPrincipal, canisterBalance + amount);
  };

  public shared ({ caller }) func checkBalance() : async ?Nat64 {
    return balances.get(caller);
  };

  public query func getAllBalances() : async [(Principal, Nat64)] {
    let iter = balances.entries();
    return Iter.toArray(iter);
  };

};
