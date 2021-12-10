// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module {
  public type AccountBalanceDfxArgs = { account : AccountIdentifier };
  public type AccountIdentifier = Text;
  public type ArchiveOptions = {
    max_message_size_bytes : ?Nat32;
    node_max_memory_size_bytes : ?Nat32;
    controller_id : Principal;
  };
  public type BlockHeight = Nat64;
  public type CanisterId = Principal;
  public type Duration = { secs : Nat64; nanos : Nat32 };
  public type HeaderField = (Text, Text);
  public type HttpRequest = {
    url : Text;
    method : Text;
    body : [Nat8];
    headers : [HeaderField];
  };
  public type HttpResponse = {
    body : [Nat8];
    headers : [HeaderField];
    status_code : Nat16;
  };
  public type Result<T, E> = {
        #Ok  : T;
        #Err : E;
  };
  public type TransferResult = Result<BlockIndex, TransferError>;
  public type ICPTs = { e8s : Nat64 };
  public type LedgerCanisterInitPayload = {
    send_whitelist : [{ _0_  : Principal }];
    minting_account : AccountIdentifier;
    transaction_window : ?Duration;
    max_message_size_bytes : ?Nat32;
    archive_options : ?ArchiveOptions;
    initial_values : [(AccountIdentifier, ICPTs)];
  };
  public type Memo = Nat64;
  public type NotifyCanisterArgs = {
    to_subaccount : ?SubAccount;
    from_subaccount : ?SubAccount;
    to_canister : Principal;
    max_fee : ICPTs;
    block_height : BlockHeight;
  };
  public type SendArgs = {
    to : AccountIdentifier;
    fee : ICPTs;
    memo : Memo;
    from_subaccount : ?SubAccount;
    created_at_time : ?TimeStamp;
    amount : ICPTs;
  };
  // Sequence number of a block produced by the ledger.
  public type BlockIndex = Nat64;
  public type SubAccount = [Nat8];
  public type TimeStamp = { timestamp_nanos : Nat64 };
  public type Transaction = {
    memo : Memo;
    created_at : BlockHeight;
    transfer : Transfer;
  };
  public type Transfer = {
    #Burn : { from : AccountIdentifier; amount : ICPTs };
    #Mint : { to : AccountIdentifier; amount : ICPTs };
    #Send : {
      to : AccountIdentifier;
      from : AccountIdentifier;
      amount : ICPTs;
    };
  };

  // Arguments for the `transfer` call.
  public type TransferArgs = {
      // Transaction memo.
      // See comments for the `Memo` type.
      memo : Memo;
      // The amount that the caller wants to transfer to the destination address.
      amount : ICPTs;
      // The amount that the caller pays for the transaction.
      // Must be 10000 e8s.
      fee : ICPTs;
      // The subaccount from which the caller wants to transfer funds.
      // If null, the ledger uses the default (all zeros) subaccount to compute the source address.
      // See comments for the `SubAccount` type.
      from_subaccount : ?SubAccount;
      // The destination account.
      // If the transfer is successful, the balance of this account increases by `amount`.
      to : AccountIdentifier;
      // The point in time when the caller created this request.
      // If null, the ledger uses current IC time as the timestamp.
      created_at_time : ?TimeStamp;
  };

  public type TransferError = {
    // The fee that the caller specified in the transfer request was not the one that the ledger expects.
    // The caller can change the transfer fee to the `expected_fee` and retry the request.
    #BadFee : { expected_fee : ICPTs };
    // The account specified by the caller doesn't have enough funds.
    #InsufficientFunds : { balance: ICPTs };
    // The request is too old.
    // The ledger only accepts requests created within a 24 hours window.
    // This is a non-recoverable error.
    #TxTooOld : { allowed_window_nanos: Nat64 };
    // The caller specified `created_at_time` that is too far in future.
    // The caller can retry the request later.
    #TxCreatedInFuture;
    // The ledger has already executed the request.
    // `duplicate_of` field is equal to the index of the block containing the original transaction.
    #TxDuplicate : { duplicate_of: BlockIndex; };
  };
  // Arguments for the `account_balance` call.
  public type AccountBalanceArgs = {
      account : Blob;
  };
  public type Self = actor {
    account_balance_dfx : shared query AccountBalanceDfxArgs -> async ICPTs;
    get_nodes : shared query () -> async [CanisterId];
    http_request : shared query HttpRequest -> async HttpResponse;
    notify_dfx : shared NotifyCanisterArgs -> async ();
    send_dfx : shared SendArgs -> async BlockHeight;
    transfer : TransferArgs       -> async TransferResult;
    account_balance : AccountBalanceArgs -> async ICPTs;
  }
}