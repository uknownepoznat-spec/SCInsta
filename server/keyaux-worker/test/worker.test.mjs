import test from "node:test";
import assert from "node:assert/strict";
import worker, { handleRequest, hashHex, base64, proofMessage, derToRaw, supportURL } from "../src/worker.mjs";

// Protocol tests use software keys only. They do NOT attest Secure Enclave or
// prove that a particular LiveContainer/signing configuration supports it.
class FakeDB {
  challenges = new Map();
  rates = new Map();
  prepare(sql) {
    const db = this;
    return {
      args: [],
      bind(...args) { this.args = args; return this; },
      async first() {
        if (sql.startsWith("INSERT INTO peki_auth_rate_limits")) {
          const [bucket, expires_at] = this.args;
          const attempts = (db.rates.get(bucket)?.attempts || 0) + 1;
          db.rates.set(bucket, { attempts, expires_at });
          return { attempts };
        }
        if (sql.startsWith("DELETE FROM peki_auth_challenges WHERE id")) {
          const [id, now] = this.args;
          const row = db.challenges.get(id);
          if (!row || row.expires_at <= now) return null;
          db.challenges.delete(id);
          return row;
        }
        throw new Error(`Unexpected first SQL: ${sql}`);
      },
      async run() {
        if (sql.startsWith("INSERT INTO peki_auth_challenges")) {
          const [id, nonce, hwid, license_hash, version, expires_at] = this.args;
          db.challenges.set(id, { id, nonce, hwid, license_hash, version, expires_at });
          return { success: true };
        }
        if (sql.startsWith("DELETE FROM peki_auth_challenges WHERE expires")) {
          for (const [id, row] of db.challenges) if (row.expires_at <= this.args[0]) db.challenges.delete(id);
          return { success: true };
        }
        if (sql.startsWith("DELETE FROM peki_auth_rate_limits WHERE expires")) {
          for (const [id, row] of db.rates) if (row.expires_at <= this.args[0]) db.rates.delete(id);
          return { success: true };
        }
        throw new Error(`Unexpected run SQL: ${sql}`);
      },
    };
  }
  async batch(statements) { return Promise.all(statements.map(statement => statement.run())); }
}

function env() {
  return { DB: new FakeDB(), KEYAUX_APP_ID: "fixture-app", APP_VERSION: "1.0",
    KEYAUX_APP_SECRET: "test-only-upstream-secret", RATE_LIMIT_PEPPER: "test-only-rate-pepper-of-at-least-32-characters",
    DISCORD_URL: "https://discord.gg/example", DISCORD_USERNAME: "example" };
}
function request(path, body, extraHeaders = {}) {
  return new Request(`https://bridge.example${path}`, { method: "POST",
    headers: { "Content-Type": "application/json", "CF-Connecting-IP": "192.0.2.10", ...extraHeaders },
    body: JSON.stringify(body) });
}
function rawToDER(raw) {
  const values = [raw.slice(0, 32), raw.slice(32)].map(integer => {
    while (integer.length > 1 && integer[0] === 0) integer = integer.slice(1);
    return integer[0] & 0x80 ? Uint8Array.of(0, ...integer) : integer;
  });
  return Uint8Array.of(0x30, values[0].length + values[1].length + 4,
    2, values[0].length, ...values[0], 2, values[1].length, ...values[1]);
}
async function fixture() {
  const config = env();
  const pair = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const raw = new Uint8Array(await crypto.subtle.exportKey("raw", pair.publicKey));
  const public_key = base64(raw);
  const key = "TEST-LICENSE-ONE";
  const license_hash = await hashHex(key);
  const response = await handleRequest(request("/v1/challenge", { version: "1.0", public_key, license_hash }), config, { now: 1000 });
  assert.equal(response.status, 200);
  const challenge = await response.json();
  const message = proofMessage(config.KEYAUX_APP_ID, "1.0", { id: challenge.challenge_id, nonce: challenge.nonce }, challenge.hwid, license_hash);
  const rawSignature = new Uint8Array(await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" }, pair.privateKey, new TextEncoder().encode(message)));
  const der = rawToDER(rawSignature);
  assert.deepEqual(derToRaw(der), rawSignature);
  return { config, pair, raw, message, challenge, body: {
    version: "1.0", public_key, key, challenge_id: challenge.challenge_id, signature: base64(der)
  } };
}
function vendor(result = { success: true }, status = 200) {
  const calls = [];
  return { calls, async fetch(url, options) {
    calls.push({ url, headers: new Headers(options.headers), body: JSON.parse(options.body), redirect: options.redirect });
    return new Response(JSON.stringify(result), { status });
  } };
}

test("a signed proof grants only after provider verification and filters provider private data", async () => {
  const item = await fixture();
  const upstream = vendor({ success: true, data: { session_token: "DO_NOT_RETURN_THIS", license: { private: "HIDDEN" } } });
  const response = await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl: upstream.fetch });
  assert.equal(response.status, 200);
  const text = await response.text();
  const result = JSON.parse(text);
  assert.equal(result.authorized, true);
  assert.equal(result.hwid, await hashHex(item.raw));
  assert.equal(result.lease_seconds, 300);
  for (const secret of [item.body.key, item.config.KEYAUX_APP_SECRET, "DO_NOT_RETURN_THIS", "HIDDEN"]) assert.ok(!text.includes(secret));
  assert.equal(upstream.calls.length, 1);
  assert.equal(upstream.calls[0].url, "https://service.keyaux.com/api/v1/licenses/verify");
  assert.equal(upstream.calls[0].headers.get("X-App-Secret"), item.config.KEYAUX_APP_SECRET);
  assert.equal(upstream.calls[0].body.hwid, result.hwid);
  assert.equal(upstream.calls[0].redirect, "manual");
});

test("a new license may activate, but existing activation does not activate again", async () => {
  const item = await fixture();
  const calls = [];
  const fetchImpl = async url => {
    calls.push(url);
    return new Response(JSON.stringify({ success: url.endsWith("/activate") }), { status: 200 });
  };
  const response = await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl });
  assert.equal(response.status, 200);
  assert.deepEqual(calls, ["https://service.keyaux.com/api/v1/licenses/verify", "https://service.keyaux.com/api/v1/licenses/activate"]);
});

test("denied, expired or HWID-mismatched provider responses never grant", async () => {
  const item = await fixture();
  const upstream = vendor({ success: false, message: "provider details should not be exposed" }, 403);
  const response = await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl: upstream.fetch });
  assert.equal(response.status, 403);
  const result = await response.json();
  assert.equal(result.authorized, false);
  assert.equal(result.error, "license_denied");
  assert.ok(!JSON.stringify(result).includes("provider details"));
});

test("a challenge is one-use even when the signature is replayed", async () => {
  const item = await fixture();
  const upstream = vendor();
  assert.equal((await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl: upstream.fetch })).status, 200);
  const replay = await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1002, fetchImpl: upstream.fetch });
  assert.equal(replay.status, 401);
  assert.equal(upstream.calls.length, 1);
});

test("concurrent replays cannot both reach the provider", async () => {
  const item = await fixture();
  const upstream = vendor();
  const responses = await Promise.all([
    handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl: upstream.fetch }),
    handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl: upstream.fetch }),
  ]);
  assert.deepEqual(responses.map(response => response.status).sort(), [200, 401]);
  assert.equal(upstream.calls.length, 1);
});

test("expired challenges cannot reach KeyAux", async () => {
  const item = await fixture();
  const upstream = vendor();
  const response = await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1091, fetchImpl: upstream.fetch });
  assert.equal(response.status, 401);
  assert.equal(upstream.calls.length, 0);
});

test("changing the license after getting a challenge is rejected", async () => {
  const item = await fixture();
  const upstream = vendor();
  const response = await handleRequest(request("/v1/license/check", { ...item.body, key: "OTHER-LICENSE" }), item.config,
    { now: 1001, fetchImpl: upstream.fetch });
  assert.equal(response.status, 401);
  assert.equal(upstream.calls.length, 0);
});

test("copying a public device code without its private key is insufficient", async () => {
  const item = await fixture();
  const attacker = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const signed = new Uint8Array(await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, attacker.privateKey,
    new TextEncoder().encode(item.message)));
  const upstream = vendor();
  const response = await handleRequest(request("/v1/license/check", { ...item.body, signature: base64(rawToDER(signed)) }), item.config,
    { now: 1001, fetchImpl: upstream.fetch });
  assert.equal(response.status, 401);
  assert.equal(upstream.calls.length, 0);
});

test("another device's public key cannot replace the challenged one", async () => {
  const item = await fixture();
  const other = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const public_key = base64(await crypto.subtle.exportKey("raw", other.publicKey));
  const upstream = vendor();
  const response = await handleRequest(request("/v1/license/check", { ...item.body, public_key }), item.config,
    { now: 1001, fetchImpl: upstream.fetch });
  assert.equal(response.status, 401);
  assert.equal(upstream.calls.length, 0);
});

test("provider outages do not activate or fail open", async () => {
  const item = await fixture();
  const upstream = vendor({ success: true }, 503);
  const response = await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl: upstream.fetch });
  assert.equal(response.status, 503);
  assert.equal((await response.json()).authorized, false);
  assert.equal(upstream.calls.length, 1);
});

test("provider redirects never grant or trigger activation", async () => {
  for (const status of [301, 302, 303, 307, 308]) {
    const item = await fixture();
    const upstream = vendor({ success: true }, status);
    const response = await handleRequest(request("/v1/license/check", item.body), item.config,
      { now: 1001, fetchImpl: upstream.fetch });
    assert.equal(response.status, 502);
    assert.equal((await response.json()).authorized, false);
    assert.equal(upstream.calls.length, 1);
    assert.equal(upstream.calls[0].redirect, "manual");
  }
});

test("malformed or truthy-string provider success fails closed", async () => {
  const item = await fixture();
  const upstream = vendor({ success: "true" });
  const response = await handleRequest(request("/v1/license/check", item.body), item.config, { now: 1001, fetchImpl: upstream.fetch });
  assert.equal(response.status, 502);
  assert.equal((await response.json()).authorized, false);
  assert.equal(upstream.calls.length, 1);
});

test("bad DER is rejected before verification", () => {
  for (const bad of [new Uint8Array(), Uint8Array.of(0x30, 0), new Uint8Array(73),
    Uint8Array.of(0x30, 8, 2, 2, 0, 1, 2, 2, 0, 1)]) assert.throws(() => derToRaw(bad));
});

test("input limits and version checks fail before provider calls", async () => {
  const config = env();
  const upstream = vendor();
  assert.equal((await handleRequest(request("/v1/challenge", { version: "old" }), config,
    { now: 1000, fetchImpl: upstream.fetch })).status, 426);
  assert.equal((await handleRequest(request("/v1/challenge", { data: "x".repeat(5000) }), config,
    { now: 1000, fetchImpl: upstream.fetch })).status, 413);
  assert.equal((await handleRequest(request("/v1/challenge", { version: "1.0", public_key: "INVALID" }), config,
    { now: 1000, fetchImpl: upstream.fetch })).status, 400);
  assert.equal(upstream.calls.length, 0);
});

test("rate limit is persisted and stops a burst before provider calls", async () => {
  const config = env();
  const upstream = vendor();
  for (let index = 0; index < 60; index++) {
    assert.equal((await handleRequest(request("/v1/challenge", { version: "old" }), config,
      { now: 1000, fetchImpl: upstream.fetch })).status, 426);
  }
  assert.equal((await handleRequest(request("/v1/challenge", { version: "old" }), config,
    { now: 1000, fetchImpl: upstream.fetch })).status, 429);
  assert.equal(upstream.calls.length, 0);
  assert.ok(!JSON.stringify([...config.DB.rates.keys()]).includes("192.0.2.10"));
});

test("there is no arbitrary proxy, Seller API, or client-secret passthrough", async () => {
  const config = env();
  const upstream = vendor();
  const response = await handleRequest(request("/api/v1/seller/delete", { url: "https://evil.example" }), config,
    { now: 1000, fetchImpl: upstream.fetch });
  assert.equal(response.status, 404);
  assert.equal(upstream.calls.length, 0);
});

test("missing server configuration fails closed", async () => {
  const config = env();
  delete config.KEYAUX_APP_SECRET;
  const response = await handleRequest(request("/v1/challenge", {}), config, { now: 1000 });
  assert.equal(response.status, 503);
  assert.equal((await response.json()).authorized, false);
});

test("unchanged example secrets fail closed rather than contacting KeyAux", async () => {
  const config = env();
  config.KEYAUX_APP_SECRET = "replace_with_a_rotated_secret";
  const upstream = vendor();
  const response = await handleRequest(request("/v1/challenge", {}), config, { now: 1000, fetchImpl: upstream.fetch });
  assert.equal(response.status, 503);
  assert.equal(upstream.calls.length, 0);
});

test("public configuration never exposes credentials and only allows Discord links", async () => {
  const config = env();
  config.DISCORD_URL = "https://evil.example/steal";
  const response = await handleRequest(new Request("https://bridge.example/v1/config"), config);
  const text = await response.text();
  assert.ok(!text.includes(config.KEYAUX_APP_SECRET));
  assert.ok(!text.includes(config.RATE_LIMIT_PEPPER));
  assert.equal(JSON.parse(text).discord_url, "");
  assert.equal(response.headers.get("Cache-Control"), "no-store");
  assert.equal(supportURL("javascript:alert(1)"), "");
  assert.equal(supportURL("https://discord.com/invite/a?redirect=evil"), "");
  assert.equal(supportURL("https://discord.gg/approved"), "https://discord.gg/approved");
});

test("scheduled cleanup removes only expired bridge state", async () => {
  const config = env();
  config.DB.challenges.set("expired", { expires_at: 0 });
  config.DB.challenges.set("future", { expires_at: Number.MAX_SAFE_INTEGER });
  config.DB.rates.set("expired", { expires_at: 0 });
  await worker.scheduled({}, config);
  assert.equal(config.DB.challenges.has("expired"), false);
  assert.equal(config.DB.challenges.has("future"), true);
  assert.equal(config.DB.rates.size, 0);
});
