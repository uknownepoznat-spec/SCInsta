import assert from "node:assert/strict";
import { createHash, generateKeyPairSync, randomUUID, sign } from "node:crypto";
import { proofMessage } from "../src/worker.mjs";

// Optional live deployment checks, not part of `npm test`. Uses a disposable
// software key and a random nonexistent license, never an app secret or a
// customer's credential. This is not Secure Enclave or iPhone validation.
const appID = "mvxsb1isyfo10q2lo1auzklj";
const version = "1.0";
const base = new URL(process.argv[2] || "https://peki-keyaux-bridge.uknownepoznat.workers.dev");
assert.ok(base.protocol === "https:" && !base.username && !base.password
  && !base.search && !base.hash && base.pathname === "/", "Provide a root HTTPS Worker URL.");

async function call(path, body) {
  const response = await fetch(new URL(path, base), {
    method: body ? "POST" : "GET",
    headers: body ? { "Content-Type": "application/json" } : {},
    body: body ? JSON.stringify(body) : undefined,
    redirect: "error",
    signal: AbortSignal.timeout(25000),
  });
  assert.equal(response.headers.get("Cache-Control"), "no-store", "License responses must not be cached.");
  const text = await response.text();
  assert.ok(text.length < 8192, "Unexpectedly large Worker response.");
  return { status: response.status, body: JSON.parse(text) };
}

function expectDenied(result, status, code, label) {
  assert.ok(result.status === status && result.body.authorized === false
    && result.body.success === false && result.body.error === code,
  `${label}: expected HTTP ${status}/${code}; received HTTP ${result.status}/${String(result.body.error || "unexpected_response")}.`);
}

async function main() {
  const config = await call("/v1/config");
  assert.ok(config.status === 200 && config.body.app_id === appID
    && config.body.version === version, "The deployed app/version does not match this project.");
  console.log("PASS: public app/version configuration");

  const pair = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const jwk = pair.publicKey.export({ format: "jwk" });
  const raw = Buffer.concat([Buffer.from([4]), Buffer.from(jwk.x, "base64url"), Buffer.from(jwk.y, "base64url")]);
  const public_key = raw.toString("base64");
  const hwid = createHash("sha256").update(raw).digest("hex");
  const key = `SMOKE-NOT-A-REAL-LICENSE-${randomUUID()}`;
  const license_hash = createHash("sha256").update(key).digest("hex");

  async function challenge() {
    const result = await call("/v1/challenge", { version, public_key, license_hash });
    const body = result.body;
    assert.ok(result.status === 200 && body.success === true
      && body.app_id === appID && body.version === version && body.hwid === hwid
      && body.license_hash === license_hash && body.expires_in === 90
      && /^[0-9a-f-]{36}$/.test(body.challenge_id) && /^[A-Za-z0-9_-]{43}$/.test(body.nonce),
    `Challenge creation failed: HTTP ${result.status}/${String(body.error || "invalid_challenge")}.`);
    return body;
  }

  function proof(body, tampered = false) {
    const message = proofMessage(appID, version, { id: body.challenge_id, nonce: body.nonce }, hwid, license_hash);
    return { version, public_key, key, challenge_id: body.challenge_id,
      signature: sign("sha256", Buffer.from(message + (tampered ? "\ntampered" : "")), pair.privateKey).toString("base64") };
  }

  const first = await challenge();
  expectDenied(await call("/v1/license/check", proof(first, true)), 401, "bad_proof", "Tampered signature");
  expectDenied(await call("/v1/license/check", proof(first)), 401, "challenge_expired", "Consumed failed challenge");
  console.log("PASS: live D1 challenges, invalid-signature rejection and one-use consumption");

  const second = await challenge();
  const denial = await call("/v1/license/check", proof(second));
  expectDenied(denial, 403, "license_denied", "Nonexistent license with a valid signature");
  assert.ok(!JSON.stringify(denial.body).includes(key), "The Worker must not echo a license credential.");
  expectDenied(await call("/v1/license/check", proof(second)), 401, "challenge_expired", "Replayed signed request");
  console.log("PASS: signed nonexistent license denied; replay denied; no credential echoed");
  console.log("These checks do not verify a valid license, secret rotation or LiveContainer/iPhone support.");
}

main().catch(error => {
  console.error(`FAIL: ${error.message}`);
  process.exitCode = 1;
});
