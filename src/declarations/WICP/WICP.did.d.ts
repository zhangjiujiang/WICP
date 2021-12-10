import type { Principal } from '@dfinity/principal';
export type AccountIdentifier = string;
export interface ApproveRequest {
  'token' : TokenIdentifier,
  'subaccount' : [] | [SubAccount],
  'allowance' : Balance,
  'spender' : Principal,
}
export type Balance = bigint;
export type BalanceResponse = { 'ok' : Balance } |
  { 'err' : CommonError__1 };
export type CommonError = { 'InvalidToken' : TokenIdentifier } |
  { 'Other' : string };
export type CommonError__1 = { 'InvalidToken' : TokenIdentifier } |
  { 'Other' : string };
export type Err = { 'userNoExist' : null } |
  { 'heightExist' : null } |
  { 'balanceEnough' : null } |
  { 'invaildHeight' : null } |
  { 'insufficientFunds' : null } |
  { 'otherErr' : null } |
  { 'queryBlockErr' : null };
export type Extension = string;
export interface ICP { 'e8s' : bigint }
export interface ICPTs { 'e8s' : bigint }
export type Memo = Array<number>;
export type Metadata = {
    'fungible' : {
      'decimals' : number,
      'metadata' : [] | [Array<number>],
      'name' : string,
      'symbol' : string,
    }
  } |
  { 'nonfungible' : { 'metadata' : [] | [Array<number>] } };
export type Result = { 'ok' : Metadata } |
  { 'err' : CommonError };
export type SubAccount = Array<number>;
export type SubAccount__1 = Array<number>;
export type TokenIdentifier = string;
export type TokenIdentifier__1 = string;
export interface TransferRequest {
  'to' : string,
  'token' : TokenIdentifier,
  'notify' : boolean,
  'from' : User,
  'memo' : Memo,
  'subaccount' : [] | [SubAccount],
  'amount' : Balance,
}
export type TransferResponse = { 'ok' : Balance } |
  {
    'err' : { 'CannotNotify' : AccountIdentifier } |
      { 'InsufficientBalance' : null } |
      { 'InvalidToken' : TokenIdentifier } |
      { 'Rejected' : null } |
      { 'Unauthorized' : AccountIdentifier } |
      { 'Other' : string }
  };
export type User = { 'principal' : Principal } |
  { 'address' : AccountIdentifier };
export type WICPResult = { 'ok' : boolean } |
  { 'err' : Err };
export interface erc20_token {
  'acceptCycles' : () => Promise<undefined>,
  'accountId' : () => Promise<string>,
  'approve' : (arg_0: ApproveRequest) => Promise<undefined>,
  'availableCycles' : () => Promise<bigint>,
  'balance' : (arg_0: string) => Promise<BalanceResponse>,
  'call_id' : (arg_0: [] | [SubAccount__1]) => Promise<string>,
  'canister_balance' : () => Promise<ICPTs>,
  'canister_id' : (arg_0: [] | [SubAccount__1]) => Promise<string>,
  'deposit' : (arg_0: [] | [SubAccount__1], arg_1: bigint) => Promise<
      WICPResult
    >,
  'extensions' : () => Promise<Array<Extension>>,
  'metadata' : (arg_0: TokenIdentifier__1) => Promise<Result>,
  'transfer' : (arg_0: TransferRequest) => Promise<TransferResponse>,
  'withdraw' : (arg_0: ICP, arg_1: string) => Promise<WICPResult>,
}
export interface _SERVICE extends erc20_token {}
