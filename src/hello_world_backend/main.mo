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

// set installer_ Principal when this canister is first installed
shared ({ caller = installer_ }) actor class LedgerSample() = this {

  /** Compulsory constants this canister must adhere to. */
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
  };

  // Invoice canister only uses transfer and balance methods of ledger canisters; these are those supertypes:
  let Ledger_ICP : SupportedToken.Actor_Supertype_ICP = actor (CANISTER_IDS.icp_ledger_canister);

  /// Account Identitier type.
  public type AccountIdentifier = {
    hash : [Nat8];
    // hash : Blob;
  };

  /// Convert bytes array to hex string.
  /// E.g `[255,255]` to "ffff"
  public func encode(array : [Nat8]) : async Text {
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

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  public shared ({ caller }) func getCallerPrincipalAndAccountId() : async Text {
    let principal = Principal.toText(caller);
    let accountIdentifier = Account.accountIdentifier(caller, Account.defaultSubaccount());
    let accountId = await accountToText({ hash = Blob.toArray(accountIdentifier) });
    
    return "Caller's Principal: " # principal # ", Account ID: " # accountId;
  };

  public shared ({ caller }) func getInstallerPrincipalAndAccountId() : async Text {
    let principal = Principal.toText(installer_);
    let accountIdentifier = Account.accountIdentifier(caller, Account.defaultSubaccount());
    let accountId = await accountToText({ hash = Blob.toArray(accountIdentifier) });
    
    return "installer_'s Principal: " # principal # ", Account ID: " # accountId;
  };

  public func getCanisterPrincipalId() : async Principal {
    return Principal.fromActor(this);
  };

  // Returns the default account identifier of this canister.
  // public func getCanisterAccountId() : async Account.AccountIdentifier {
  //   Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount())
  // };

  /// Return the Text of the account identifier.
  public func accountToText(p : AccountIdentifier) : async Text {
    let crc = CRC32.crc32(p.hash);
    let aid_bytes = Array.append<Nat8>(crc, p.hash);

    return await encode(aid_bytes);
  };

  public func getCanisterAccountId() : async Text {
    let accountIdentifier = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
    return await accountToText({ hash = Blob.toArray(accountIdentifier) });
  };

  // public func getCanisterAccountId() : async Text {
  //   return await accountToText(Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount()));
  // };

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
      canisterId = await getCanisterPrincipalId();
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

  // public shared ({ caller }) func withdrawICP(amount : Nat64) : async Result.Result<Text, Text> {
  //   try {
  //     let to = Principal.toText(caller);
  //     let result = await Ledger_ICP.send({ to = to; amount = amount });
  //     switch result {
  //       case (#ok _) { #ok("Withdrawal successful.") };
  //       case (#err e) { #err("Withdrawal failed: " # e) };
  //     };
  //   } catch e {
  //     #err("Error: " # Error.message(e));
  //   };
  // };

  public shared ({ caller }) func withdrawICP(amount : Nat64) : async Result.Result<Text, Text> {
    let now = Time.now();
    let canisterAccountId = Account.accountIdentifier(Principal.fromActor(this), Account.defaultSubaccount());
    let canisterBalance = #ICP(await Ledger_ICP.account_balance({ account = canisterAccountId }));
    let res = await Ledger_ICP.transfer({
      memo = 0; //Any transaction can store an 8-byte memo — this memo field is used by the Rosetta API to store the nonce that distinguishes between transactions. However, other uses for the field are possible.
      from_subaccount = null;
      to = Account.accountIdentifier(installer_, Account.defaultSubaccount());
      amount = { e8s = amount };
      fee = { e8s = 10_000 };
      created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(now)) };
    });
    switch (res) {
      case (#Ok(blockIndex)) {
        return #ok("Paid reward to " # debug_show installer_ # " in block " # debug_show blockIndex);
      };
      case (#Err(#InsufficientFunds { balance })) {
        let errMsg = "Top me up! The balance is only " # debug_show balance # " e8s";
        throw Error.reject(errMsg);
        return #err(errMsg);
      };
      case (#Err(other)) {
        let errMsg = "Unexpected error: " # debug_show other;
        throw Error.reject(errMsg);
        return #err(errMsg);
      };
    };
  };
};
