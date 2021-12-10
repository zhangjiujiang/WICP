export const idlFactory = ({ IDL }) => {
  const TokenIdentifier = IDL.Text;
  const SubAccount = IDL.Vec(IDL.Nat8);
  const Balance = IDL.Nat64;
  const ApproveRequest = IDL.Record({
    'token' : TokenIdentifier,
    'subaccount' : IDL.Opt(SubAccount),
    'allowance' : Balance,
    'spender' : IDL.Principal,
  });
  const CommonError__1 = IDL.Variant({
    'InvalidToken' : TokenIdentifier,
    'Other' : IDL.Text,
  });
  const BalanceResponse = IDL.Variant({
    'ok' : Balance,
    'err' : CommonError__1,
  });
  const SubAccount__1 = IDL.Vec(IDL.Nat8);
  const ICPTs = IDL.Record({ 'e8s' : IDL.Nat64 });
  const Err = IDL.Variant({
    'userNoExist' : IDL.Null,
    'heightExist' : IDL.Null,
    'balanceEnough' : IDL.Null,
    'invaildHeight' : IDL.Null,
    'insufficientFunds' : IDL.Null,
    'otherErr' : IDL.Null,
    'queryBlockErr' : IDL.Null,
  });
  const WICPResult = IDL.Variant({ 'ok' : IDL.Bool, 'err' : Err });
  const Extension = IDL.Text;
  const TokenIdentifier__1 = IDL.Text;
  const Metadata = IDL.Variant({
    'fungible' : IDL.Record({
      'decimals' : IDL.Nat8,
      'metadata' : IDL.Opt(IDL.Vec(IDL.Nat8)),
      'name' : IDL.Text,
      'symbol' : IDL.Text,
    }),
    'nonfungible' : IDL.Record({ 'metadata' : IDL.Opt(IDL.Vec(IDL.Nat8)) }),
  });
  const CommonError = IDL.Variant({
    'InvalidToken' : TokenIdentifier,
    'Other' : IDL.Text,
  });
  const Result = IDL.Variant({ 'ok' : Metadata, 'err' : CommonError });
  const AccountIdentifier = IDL.Text;
  const User = IDL.Variant({
    'principal' : IDL.Principal,
    'address' : AccountIdentifier,
  });
  const Memo = IDL.Vec(IDL.Nat8);
  const TransferRequest = IDL.Record({
    'to' : IDL.Text,
    'token' : TokenIdentifier,
    'notify' : IDL.Bool,
    'from' : User,
    'memo' : Memo,
    'subaccount' : IDL.Opt(SubAccount),
    'amount' : Balance,
  });
  const TransferResponse = IDL.Variant({
    'ok' : Balance,
    'err' : IDL.Variant({
      'CannotNotify' : AccountIdentifier,
      'InsufficientBalance' : IDL.Null,
      'InvalidToken' : TokenIdentifier,
      'Rejected' : IDL.Null,
      'Unauthorized' : AccountIdentifier,
      'Other' : IDL.Text,
    }),
  });
  const ICP = IDL.Record({ 'e8s' : IDL.Nat64 });
  const erc20_token = IDL.Service({
    'acceptCycles' : IDL.Func([], [], []),
    'accountId' : IDL.Func([], [IDL.Text], []),
    'approve' : IDL.Func([ApproveRequest], [], []),
    'availableCycles' : IDL.Func([], [IDL.Nat], ['query']),
    'balance' : IDL.Func([IDL.Text], [BalanceResponse], ['query']),
    'call_id' : IDL.Func([IDL.Opt(SubAccount__1)], [IDL.Text], []),
    'canister_balance' : IDL.Func([], [ICPTs], []),
    'canister_id' : IDL.Func([IDL.Opt(SubAccount__1)], [IDL.Text], []),
    'deposit' : IDL.Func([IDL.Opt(SubAccount__1), IDL.Nat64], [WICPResult], []),
    'extensions' : IDL.Func([], [IDL.Vec(Extension)], ['query']),
    'metadata' : IDL.Func([TokenIdentifier__1], [Result], ['query']),
    'transfer' : IDL.Func([TransferRequest], [TransferResponse], []),
    'withdraw' : IDL.Func([ICP, IDL.Text], [WICPResult], []),
  });
  return erc20_token;
};
export const init = ({ IDL }) => {
  return [IDL.Text, IDL.Text, IDL.Nat8, IDL.Principal];
};
