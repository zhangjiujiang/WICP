import { idlFactory as wicp_idl , canisterId as wicp_id} from "../../declarations/WICP";
import { idlFactory as ledger_idl, canisterId as ledger_id } from "./ledger.js";
import {
  Actor,
  HttpAgent,
  blobFromUint8Array,
  blobToHex,
} from "@dfinity/agent";
// import {
//   ,
  
// } from "@dfinity/candid";
import { Principal } from "@dfinity/principal";
import { Ed25519KeyIdentity } from "@dfinity/identity";
import { mnemonicToEntropy} from "bip39";

const seed = "clever knock pull thought milk anxiety slush canvas net pink truly shed garlic flock explain inmate daughter income network almost twin sorry act inject";
function generate(seed) {
  const entropy = mnemonicToEntropy(seed);
  const identity = Ed25519KeyIdentity.generate(entropy);
  localStorage.setItem("local_identity", JSON.stringify(identity));
  return identity;
};

function newIdentity() {
  const entropy = crypto.getRandomValues(new Uint8Array(32));
  const identity = Ed25519KeyIdentity.generate(entropy);
  localStorage.setItem("local_identity", JSON.stringify(identity));
  return identity;
}

function readIdentity() {
  const stored = localStorage.getItem("local_identity");
  if (!stored) {
    return generate(seed);
  }
  try {
    return Ed25519KeyIdentity.fromJSON(stored);
  } catch (error) {
    console.log(error);
    return generate(seed);
  }
}

function principalToAccountId(principal, subaccount) {
  const shaObj = sha224.create();
  shaObj.update("\x0Aaccount-id");
  shaObj.update(principal.toBlob());
  shaObj.update(subaccount ? subaccount : new Uint8Array(32));
  const hash = new Uint8Array(shaObj.array());
  const crc = crc32.buf(hash);
  const blob = blobFromUint8Array(
    new Uint8Array([
      (crc >> 24) & 0xff,
      (crc >> 16) & 0xff,
      (crc >> 8) & 0xff,
      crc & 0xff,
      ...hash,
    ])
  );
  return blobToHex(blob);
}

function buildSubAccountId(principal) {
  const blob = principal.toBlob();
  const subAccount = new Uint8Array(32);
  subAccount[0] = blob.length;
  subAccount.set(blob, 1);
  return subAccount;
}

const FEE = { e8s: 10000n };
const TOP_UP_CANISTER_MEMO = BigInt(0x50555054);
BigInt.prototype.toJSON = function () {
  return Number(this);
};


// const identity = readIdentity();
// const principal = identity.getPrincipal();
const account = principalToAccountId(wicp_id);
// document.getElementById("account").value = account;

const agent = new HttpAgent({ identity: readIdentity() });
const ledger = Actor.createActor(ledger_idl, { agent, canisterId: ledger_id });
const wicp = Actor.createActor(wicp_idl, { agent, canisterId: wicp_id });

document.getElementById('deposit').addEventListener('click', async () => {
  const wicp_pid = Principal.fromText(wicp_id);
  console.log(wicp_pid)
  const to_subaccount = buildSubAccountId(wicp_pid);
  const account = principalToAccountId(wicp_pid, to_subaccount);
  const amount = parseInt(document.getElementById("amount").value);
  const block_height = await ledger.send_dfx({
    to: account,
    fee: FEE,
    memo: TOP_UP_CANISTER_MEMO,
    from_subaccount: [],
    created_at_time: [],
    amount,
  });
  console.log("block_height"+block_height)
  var result = await wicp.deposit( null,block_height);
  console.log("deposit result :"+result);
});

