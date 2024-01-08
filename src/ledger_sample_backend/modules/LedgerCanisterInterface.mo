module {
    public type Tokens = { e8s : Nat64 };

    public type Operation = {
        #Approve : {
            fee : Tokens;
            from : [Nat8];
            allowance_e8s : Int;
            allowance : Tokens;
            expires_at : ?{ timestamp_nanos : Nat64 };
            spender : [Nat8];
        };
        #Burn : { from : [Nat8]; amount : Tokens; spender : ?[Nat8] };
        #Mint : { to : [Nat8]; amount : Tokens };
        #Transfer : {
            to : [Nat8];
            fee : Tokens;
            from : [Nat8];
            amount : Tokens;
        };
        #TransferFrom : {
            to : [Nat8];
            fee : Tokens;
            from : [Nat8];
            amount : Tokens;
            spender : [Nat8];
        };
    };

    public type Transaction = {
        memo : Nat64;
        icrc1_memo : ?[Nat8];
        operation : ?Operation;
        created_at_time : { timestamp_nanos : Nat64 };
    };

    public type Block = {
        transaction : Transaction;
        timestamp : { timestamp_nanos : Nat64 };
        parent_hash : ?[Nat8];
    };

    public type ArchivedBlock = {
        callback : shared ({ start : Nat64; length : Nat64 }) -> async {
            #Ok : { blocks : [Block] };
            #Err : {
                #BadFirstBlockIndex : {
                    requested_index : Nat64;
                    first_valid_index : Nat64;
                };
                #Other : { error_message : Text; error_code : Nat64 };
            };
        };
        start : Nat64;
        length : Nat64;
    };

    public type GetBlocksArgs = { start : Nat64; length : Nat64 };
    public type QueryBlocksResponse = {
        certificate : ?[Nat8];
        blocks : [Block];
        chain_length : Nat64;
        first_block_index : Nat64;
        archived_blocks : [ArchivedBlock];
    };

    public type Memo = Nat64;
    public type Subaccount = Blob;
    public type Timestamp = { timestamp_nanos : Nat64 };
    /** Arguments for the `transfer` call.  */
    public type TransferArgs = {
        memo : Memo;
        amount : Tokens;
        fee : Tokens;
        from_subaccount : ?Subaccount;
        to : AccountIdentifier;
        created_at_time : ?Timestamp;
    };

    // type TransferArgs = {
    //     to : [Nat8];
    //     fee : Tokens;
    //     memo : Nat64;
    //     from_subaccount : ?[Nat8];
    //     created_at_time : ?{ timestamp_nanos : Nat64 };
    //     amount : Tokens;
    // };

    type TransferResponse = {
        #Ok : Nat64;
        #Err : TransferError;
    };

    type TransferError = {
        #TxTooOld : { allowed_window_nanos : Nat64 };
        #BadFee : { expected_fee : Tokens };
        #TxDuplicate : { duplicate_of : Nat64 };
        #TxCreatedInFuture : ();
        #InsufficientFunds : { balance : Tokens };
    };

    public type BinaryAccountBalanceArgs = { account : [Nat8] };

    /** AccountIdentifier is a 32-byte array.
   The first 4 bytes is big-endian encoding of a CRC32 checksum of the last 28 bytes. */
    public type AccountIdentifier = Blob;

    public type AccountBalanceArgs = { account : AccountIdentifier };

    public type LedgerCanister = actor {
        account_balance : shared query AccountBalanceArgs -> async Tokens;
        transfer : (TransferArgs) -> async TransferResponse;
        query_blocks : shared (GetBlocksArgs) -> async QueryBlocksResponse;
    };
};
