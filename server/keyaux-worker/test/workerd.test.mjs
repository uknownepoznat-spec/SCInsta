import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { createHash, generateKeyPairSync, randomUUID, sign } from "node:crypto";
import { Miniflare, convertV4MiniflareOptions } from "miniflare";
import { proofMessage } from "../src/worker.mjs";

test("workerd verifies signed proofs against real local D1 without following provider redirects", async t => {
  const appID = "runtime-fixture-app";
  const version = "1.0";
  const secret = "runtime-test-only-secret";
  let providerStatus = 200;
  const providerCalls = [];
  const mf = new Miniflare(convertV4MiniflareOptions({
    modules: true,
    scriptPath: fileURLToPath(new URL("../src/worker.mjs", import.meta.url)),
    compatibilityDate: "2026-11-21",
    d1Databases: ["DB"],
    bindings: { KEYAUX_APP_ID: appID, APP_VERSION: version,
      KEYAUX_APP_SECRET: secret, RATE_LIMIT_PEPPER: "runtime-only-pepper-at-least-32-characters" },
    outboundService: async request => {
      assert.equal(request.url, "https://service.keyaux.com/api/v1/licenses/verify");
      assert.equal(request.headers.get("X-App-Secret"), secret);
      providerCalls.push(request.url);
      return new Response(JSON.stringify({ success: true }), {
        status: providerStatus,
        headers: providerStatus === 302 ? { Location: "https://untrusted.invalid/never-forward" } : {},
      });
    },
  }));
  t.after(() => mf.dispose());
  const db = await mf.getD1Database("DB");
  const migration = await readFile(new URL("../migrations/0001_auth_state.sql", import.meta.url), "utf8");
  await db.batch(migration.split(";").map(sql => sql.trim()).filter(Boolean).map(sql => db.prepare(sql)));

  const pair = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const jwk = pair.publicKey.export({ format: "jwk" });
  const raw = Buffer.concat([Buffer.from([4]), Buffer.from(jwk.x, "base64url"), Buffer.from(jwk.y, "base64url")]);
  const public_key = raw.toString("base64");
  const hwid = createHash("sha256").update(raw).digest("hex");
  const key = `RUNTIME-TEST-${randomUUID()}`;
  const license_hash = createHash("sha256").update(key).digest("hex");
  async function post(path, body) {
    return mf.dispatchFetch(`https://bridge.invalid${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "CF-Connecting-IP": "192.0.2.20" },
      body: JSON.stringify(body),
    });
  }
  async function signedRequest() {
    const response = await post("/v1/challenge", { version, public_key, license_hash });
    assert.equal(response.status, 200);
    const challenge = await response.json();
    assert.equal(challenge.hwid, hwid);
    const message = proofMessage(appID, version, { id: challenge.challenge_id, nonce: challenge.nonce }, hwid, license_hash);
    return { version, public_key, key, challenge_id: challenge.challenge_id,
      signature: sign("sha256", Buffer.from(message), pair.privateKey).toString("base64") };
  }

  const first = await signedRequest();
  const allowed = await post("/v1/license/check", first);
  assert.equal(allowed.status, 200);
  assert.equal((await allowed.json()).authorized, true);
  assert.equal(providerCalls.length, 1, "workerd must accept the outbound fetch options");

  const replay = await post("/v1/license/check", first);
  assert.equal(replay.status, 401);
  assert.equal(providerCalls.length, 1, "real D1 must consume the challenge once");

  providerStatus = 302;
  const redirected = await post("/v1/license/check", await signedRequest());
  assert.equal(redirected.status, 502);
  assert.equal((await redirected.json()).authorized, false);
  assert.equal(providerCalls.length, 2, "redirects must never be followed or cause activation");
});
