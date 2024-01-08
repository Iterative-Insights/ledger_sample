module {
    public type Time = Nat64;
    public type ICPTs = Nat64;
    public type Subaccount = Blob;
    public type Memo = Nat64;
    public type BlockHeight = Nat64;

    public type TransactionError = { #error : Text };

    public type Tokens = { e8s : Nat64 };

    public type Operation = {
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

    public type Transaction = {
        memo : Nat64;
        icrc1_memo : ?[Nat8];
        operation : Operation;
        created_at_time : ?{ timestamp_nanos : Nat64 };
    };

    public type GetTransactionsResponse = {
        #ok : { transactions : [Transaction]; has_more : Bool };
        #error : TransactionError;
    };

    public type TransactionWithId = { id : Nat64; transaction : Transaction };

    public type GetAccountIdentifierTransactionsResponse = {
        balance : Nat64;
        transactions : [TransactionWithId];
        oldest_tx_id : ?Nat64;
    };

    public type GetAccountIdentifierTransactionsError = { message : Text };

    public type GetAccountIdentifierTransactionsArgs = {
        max_results : Nat64;
        start : ?Nat64;
        account_identifier : Text;
    };

    public type GetAccountIdentifierTransactionsResult = {
        #Ok : GetAccountIdentifierTransactionsResponse;
        #Err : GetAccountIdentifierTransactionsError;
    };

    public type Account = { owner : Principal; subaccount : ?[Nat8] };

    public type GetAccountTransactionsArgs = {
        account : Account;
        // The txid of the last transaction seen by the client.
        // If None then the results will start from the most recent
        // txid.
        start : ?Nat;
        // Maximum number of transactions to fetch.
        max_results : Nat;
    };

    public type GetBlocksRequest = { start : Nat; length : Nat };

    public type GetBlocksResponse = { blocks : [[Nat8]]; chain_length : Nat64 };

    public type Status = { num_blocks_synced : Nat64 };

    public type IndexCanister = actor {
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
};
