/*
ERC20 - note the following:
-No notifications (can be added)
-All tokenids are ignored
-You can use the canister address as the token id
-Memo is ignored
-No transferFrom (as transfer includes a from field)
*/
import AID "../util/AccountIdentifier";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import ExtAllowance "../ext/Allowance";
import ExtCommon "../ext/Common";
import ExtCore "../ext/Core";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Common "../types/common";
import Ledger "../types/ledger";
import Block "../types/block";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Blob "mo:base/Blob";
import AviateAID "mo:principal/blob/AccountIdentifier";

actor class erc20_token(init_name: Text, init_symbol: Text, init_decimals: Nat8,init_admin: Principal) = this {
    // Types
    type AccountIdentifier = ExtCore.AccountIdentifier;
    type SubAccount = ExtCore.SubAccount;
    type User = ExtCore.User;
    type Balance = ExtCore.Balance;
    type TokenIdentifier = ExtCore.TokenIdentifier;
    type Extension = ExtCore.Extension;
    type CommonError = ExtCore.CommonError;

    type BalanceResponse = ExtCore.BalanceResponse;
    type TransferRequest = ExtCore.TransferRequest;
    type TransferResponse = ExtCore.TransferResponse;
    type AllowanceRequest = ExtAllowance.AllowanceRequest;
    type ApproveRequest = ExtAllowance.ApproveRequest;

    type Metadata = ExtCommon.Metadata;
  
    public type ICP = {
        e8s : Nat64;
    };

    private let EXTENSIONS : [Extension] = ["@ext/common", "@ext/allowance"];

    private stable var _balancesState : [(Principal, Balance)] = [];
    private stable var _ledgerState : [(Nat64, Principal)] = [];
    private stable var _admin : Principal = init_admin; 

    private func _hash(h:Nat64) : Hash.Hash {
        Nat32.fromNat(Nat64.toNat(h));
    };
    private var _balances : HashMap.HashMap<Principal, Balance> = HashMap.fromIter(_balancesState.vals(), 0, Principal.equal, Principal.hash);
    private var _allowances = HashMap.HashMap<AccountIdentifier, HashMap.HashMap<Principal, Balance>>(1, AID.equal, AID.hash);
    private var _ledgerCache : HashMap.HashMap<Nat64,Principal> = HashMap.fromIter(_ledgerState.vals(),0,Nat64.equal,_hash);
    private var ICP_FEE : Nat64 = 10000;

    //State functions
    system func preupgrade() {
        _balancesState := Iter.toArray(_balances.entries());
        //Allowances are not stable, they are lost during upgrades...
        _ledgerState := Iter.toArray(_ledgerCache.entries());
    };
    system func postupgrade() {
        _balancesState := [];
        _ledgerState := [];
    };

    //Initial state - could set via class setter
    private stable let METADATA : Metadata = #fungible({
        name = init_name;
        symbol = init_symbol;
        decimals = init_decimals;
        metadata = null;
    }); 

    public shared(msg) func transfer(request: TransferRequest) : async TransferResponse {
        let owner = ExtCore.User.toAID(request.from);
        let spender = AID.fromPrincipal(msg.caller, request.subaccount);
    
        switch (_balances.get(msg.caller)) {
            case (?owner_balance) {
                if (owner_balance >= request.amount) {
                    if (AID.equal(owner, spender) == false) {
                        //Operator is not owner, so we need to validate here
                        switch (_allowances.get(owner)) {
                            case (?owner_allowances) {
                                switch (owner_allowances.get(msg.caller)) {
                                    case (?spender_allowance) {
                                        if (spender_allowance < request.amount) {
                                            return #err(#Other("Spender allowance exhausted"));
                                        } else {
                                            // 减去授权金额
                                            var spender_allowance_new : Balance = spender_allowance - request.amount;
                                            owner_allowances.put(msg.caller, spender_allowance_new);
                                            _allowances.put(owner, owner_allowances);
                                        };
                                    };
                                    case (_) {
                                        return #err(#Unauthorized(spender));
                                    };
                                };
                            };
                            case (_) {
                                return #err(#Unauthorized(spender));
                            };
                        };
                    };
                    //扣除手续费
                    var result = _charge_fee(msg.caller,Principal.fromActor(this),ICP_FEE);
                    switch(result) {
                        case(#ok(true)){

                        };
                        case _ {
                            return #err(#InsufficientBalance);
                        };
                    };
                    // 扣除from用户费用
                    var owner_balance_new : Balance = owner_balance - request.amount;
                    _balances.put(msg.caller, owner_balance_new);
                    // 添加to用户费用
                    let receiver = Principal.fromText(request.to);
                    var receiver_balance_new = switch (_balances.get(receiver)) {
                        case (?receiver_balance) {
                            receiver_balance + request.amount - ICP_FEE;
                        };
                        case (_) {
                            request.amount - ICP_FEE;
                        };
                    };
                    _balances.put(receiver, receiver_balance_new);
                    return #ok(request.amount);
                } else {
                    return #err(#InsufficientBalance);
                };
            };
            case (_) {
                return #err(#InsufficientBalance);
            };
        };
    };

    public shared(msg) func approve(request: ApproveRequest) : async () {
        let owner = AID.fromPrincipal(msg.caller, request.subaccount);
        switch (_allowances.get(owner)) {
            case (?owner_allowances) {
                owner_allowances.put(request.spender, request.allowance);
                _allowances.put(owner, owner_allowances);
            };
            case (_) {
                var temp = HashMap.HashMap<Principal, Balance>(1, Principal.equal, Principal.hash);
                temp.put(request.spender, request.allowance);
                _allowances.put(owner, temp);
            };
        };
    };

    public type WICPResult = Result.Result<Bool,Err>;
    let block : Block.Self = actor("ockk2-xaaaa-aaaai-aaaua-cai");
    let ledger : Ledger.Self = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
    public type Err = {
        #heightExist;
        #queryBlockErr;
        #invaildHeight;
        #balanceEnough;
        #userNoExist;
        #insufficientFunds;
        #otherErr;
    };

    // Charge transfer fee
    private func _charge_fee(user: Principal,fee_to: Principal,fee: Nat64) : WICPResult {
        if(fee > 0){
            var from_balance_new = switch (_balances.get(user)) {
                case (?receiver_balance) {
                    if (receiver_balance < fee) {
                        return #err(#balanceEnough);
                    };
                    receiver_balance - fee;
                };
                case (_) {
                    return #err(#balanceEnough);
                };
            };
            _balances.put(user, from_balance_new);

            var to_balance_new = switch (_balances.get(fee_to)) {
                case (?receiver_balance) {
                    receiver_balance + fee;
                };
                case (_) {
                    fee;
                };
            };
            _balances.put(fee_to, to_balance_new);
            return #ok(true);
        };
        return #ok(true);
    };


    public shared(msg) func deposit(sub_account: ?AID.SubAccount,height: Nat64) : async WICPResult {
        switch(_ledgerCache.get(height)) {
            case (?height) {
                return #err(#heightExist);
            };
            case _ {
                let tx = await block.block(height);
                switch(tx){
                    case(#Ok(#Ok(block))){
                        switch(block.transaction.transfer){
                            case(#Send(send)) {
                               
                                // todo
                                if(send.to == AID.fromPrincipal(Principal.fromActor(this),sub_account) and send.from == AID.fromPrincipal(msg.caller,sub_account)){
                                    _ledgerCache.put(height,msg.caller);
                                    // add wicp
                                    var receiver_balance_new = switch (_balances.get(msg.caller)) {
                                        case (?receiver_balance) {
                                            receiver_balance + send.amount.e8s;
                                        };
                                        case (_) {
                                            send.amount.e8s;
                                        };
                                    };
                                    _balances.put(msg.caller, receiver_balance_new);
                                    return #ok(true);
                                };
                                return #err(#invaildHeight);
                            };
                            case(_) return #err(#queryBlockErr);
                        };
                    };    
                    case(_) { return #err(#queryBlockErr); }
                }   
            }
        }       
    };

    public shared(msg) func withdraw(request: Common.ICP,to: Text) : async WICPResult {
        switch (_balances.get(msg.caller)) {
            case (?balance) {
                if (request.e8s > balance) {
                    return #err(#balanceEnough);
                };
                // 减去提取的数量
                var balance_new : Balance = balance - request.e8s;
                let now = Time.now();
                _balances.put(msg.caller, balance_new);
                
                // ledger转账需要收取手续费
                let res = await ledger.transfer({
                    memo = request.e8s;
                    from_subaccount = null;
                    to = to;
                    amount = { e8s = request.e8s - ICP_FEE };
                    fee = { e8s = ICP_FEE };
                    created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(now)) };
                });

                switch (res) {
                    case (#Ok(blockIndex)) {
                        return #ok(true);
                    };
                    case (#Err(#InsufficientFunds { balance })) {
                        return #err(#insufficientFunds);
                    };
                    case (#Err(other)) {
                        return #err(#otherErr);
                    };
                };
                return #err(#otherErr);
            };
            case (_) {
                return #err(#userNoExist);
            };
        };
    };


    public query func extensions() : async [Extension] {
        EXTENSIONS;
    };

    public query func balance(principal : Text) : async BalanceResponse {
        switch (_balances.get(Principal.fromText(principal))) {
            case (?balance) {
                return #ok(balance);
            };
            case (_) {
                return #ok(0);
            };
        }
    };
    
    public shared(msg) func call_id(sub_account: ?AID.SubAccount) : async Text {
        Principal.toText(msg.caller)
        //AID.fromPrincipal(msg.caller,sub_account)
    };

    public func canister_id(sub_account: ?AID.SubAccount) : async Text {
        AID.fromPrincipal(Principal.fromActor(this),sub_account)
    };

    public func accountId() : async Text {
        AviateAID.toText(aId());
    };

    private func aId() : AviateAID.AccountIdentifier {
        AviateAID.fromPrincipal(Principal.fromActor(this), null);
    };

    public func canister_balance() : async Ledger.ICPTs {
        await ledger.account_balance({
            account = aId();
        });
    };

    public query func metadata(token : TokenIdentifier) : async Result.Result<Metadata, CommonError> {
        #ok(METADATA);
    };

    //Internal cycle management - good general case
    public func acceptCycles() : async () {
        let available = Cycles.available();
        let accepted = Cycles.accept(available);
        assert (accepted == available);
    };

    public query func availableCycles() : async Nat {
        return Cycles.balance();
    };
}