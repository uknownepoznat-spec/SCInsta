const PROVIDER = "https://service.keyaux.com";
const encoder = new TextEncoder();
const MAX_BODY = 4096;
const LEASE_SECONDS = 300;
const CHALLENGE_SECONDS = 90;

export class AuthError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export function supportURL(value = "") {
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" || url.username || url.password || url.port || url.search || url.hash) return "";
    if (url.hostname === "discord.gg" && /^\/[A-Za-z0-9-]+\/?$/.test(url.pathname)) return url.href;
    if (url.hostname === "discord.com" && /^\/(invite\/[A-Za-z0-9-]+|users\/[0-9]+)\/?$/.test(url.pathname)) return url.href;
  } catch {}
  return "";
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
    },
  });
}

export function base64(bytes) {
  return btoa(String.fromCharCode(...new Uint8Array(bytes)));
}

function decode64(value, maxLength) {
  if (typeof value !== "string" || value.length > maxLength || !/^[A-Za-z0-9+/]+={0,2}$/.test(value)) {
    throw new AuthError(400, "bad_proof", "Invalid device proof.");
  }
  try {
    return Uint8Array.from(atob(value), char => char.charCodeAt(0));
  } catch {
    throw new AuthError(400, "bad_proof", "Invalid device proof.");
  }
}

export async function hashHex(value) {
  const bytes = typeof value === "string" ? encoder.encode(value) : value;
  const hash = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
  return [...hash].map(value => value.toString(16).padStart(2, "0")).join("");
}

export function proofMessage(appID, version, challenge, hwid, licenseHash) {
  return ["peki-license-v1", appID, version, challenge.id, challenge.nonce, hwid, licenseHash].join("\n");
}

// Security.framework signs ECDSA as DER; WebCrypto verifies IEEE-P1363 r||s.
export function derToRaw(signature) {
  if (signature.length < 8 || signature.length > 72 || signature[0] !== 0x30
      || signature[1] !== signature.length - 2) throw new AuthError(400, "bad_proof", "Invalid device signature.");
  let offset = 2;
  const result = new Uint8Array(64);
  for (let part = 0; part < 2; part++) {
    if (signature[offset++] !== 0x02) throw new AuthError(400, "bad_proof", "Invalid device signature.");
    const length = signature[offset++];
    if (!length || length > 33 || offset + length > signature.length || (signature[offset] & 0x80)) {
      throw new AuthError(400, "bad_proof", "Invalid device signature.");
    }
    let integer = signature.slice(offset, offset + length);
    offset += length;
    if (integer.length > 1 && integer[0] === 0) {
      if (!(integer[1] & 0x80)) throw new AuthError(400, "bad_proof", "Non-canonical device signature.");
      integer = integer.slice(1);
    }
    if (integer.length > 32) throw new AuthError(400, "bad_proof", "Invalid device signature.");
    result.set(integer, part * 32 + 32 - integer.length);
  }
  if (offset !== signature.length) throw new AuthError(400, "bad_proof", "Invalid device signature.");
  return result;
}

async function readJSON(request) {
  if (request.headers.get("Content-Type")?.split(";")[0].trim().toLowerCase() !== "application/json") {
    throw new AuthError(415, "json_required", "Send a JSON request.");
  }
  const reader = request.body?.getReader();
  if (!reader) throw new AuthError(400, "bad_request", "Missing request body.");
  const chunks = [];
  let length = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    length += value.length;
    if (length > MAX_BODY) {
      await reader.cancel();
      throw new AuthError(413, "too_large", "Request is too large.");
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  try {
    const body = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes));
    if (!body || typeof body !== "object" || Array.isArray(body)) throw new Error();
    return body;
  } catch {
    throw new AuthError(400, "bad_request", "Invalid JSON request.");
  }
}

async function publicKey(value) {
  const bytes = decode64(value, 100);
  if (bytes.length !== 65 || bytes[0] !== 4) throw new AuthError(400, "bad_proof", "Invalid P-256 public key.");
  try {
    const key = await crypto.subtle.importKey("raw", bytes, { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"]);
    return { key, hwid: await hashHex(bytes) };
  } catch {
    throw new AuthError(400, "bad_proof", "Invalid P-256 public key.");
  }
}

function requireConfiguration(env) {
  if (!env.DB || !env.KEYAUX_APP_ID || !env.APP_VERSION || !env.KEYAUX_APP_SECRET
      || typeof env.RATE_LIMIT_PEPPER !== "string" || env.RATE_LIMIT_PEPPER.length < 32
      || env.RATE_LIMIT_PEPPER.startsWith("replace_") || env.KEYAUX_APP_SECRET.startsWith("replace_")) {
    throw new AuthError(503, "not_configured", "The license server is not configured. Contact the developer.");
  }
}

async function rateLimit(request, env, now) {
  // Cloudflare supplies this header. Never use an arbitrary client-supplied HWID
  // as the only rate-limit identity. Persist only a salted hash, not the raw IP.
  const ip = request.headers.get("CF-Connecting-IP") || "unknown";
  const identifier = await hashHex(`${env.RATE_LIMIT_PEPPER}\n${ip}`);
  const minute = Math.floor(now / 60);
  const row = await env.DB.prepare(
    "INSERT INTO peki_auth_rate_limits (bucket, attempts, expires_at) VALUES (?, 1, ?) " +
    "ON CONFLICT(bucket) DO UPDATE SET attempts = attempts + 1 RETURNING attempts"
  ).bind(`${identifier}:${minute}`, (minute + 2) * 60).first();
  if (!row || row.attempts > 60) throw new AuthError(429, "rate_limited", "Too many attempts. Please wait a minute.");
}

async function providerRequest(path, body, env, fetchImpl) {
  let response;
  try {
    response = await fetchImpl(`${PROVIDER}/api/v1/licenses/${path}`, {
      method: "POST",
      // Workers supports only manual/follow, not Fetch's "error" mode.
      // Do not forward the app secret or license to a redirect destination.
      redirect: "manual",
      headers: { "Content-Type": "application/json", "X-App-Secret": env.KEYAUX_APP_SECRET },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(10000),
    });
  } catch {
    throw new AuthError(503, "provider_unavailable", "The license service is unavailable. Please try again.");
  }
  if (response.status >= 300 && response.status < 400) {
    throw new AuthError(502, "provider_response", "The license service returned an unsupported response.");
  }
  if (response.status >= 500 || response.status === 429) {
    throw new AuthError(503, "provider_unavailable", "The license service is unavailable. Please try again.");
  }
  let result;
  try {
    // Do not pass through provider messages, sessions, secrets or user data.
    const text = await response.text();
    if (text.length > 65536) throw new Error();
    result = JSON.parse(text);
    if (!result || typeof result.success !== "boolean") throw new Error();
  } catch {
    throw new AuthError(502, "provider_response", "The license service returned an unsupported response.");
  }
  return response.ok && result.success === true;
}

export async function handleRequest(request, env, { fetchImpl = fetch, now = Math.floor(Date.now() / 1000) } = {}) {
  try {
    const path = new URL(request.url).pathname;
    if (request.method === "GET" && path === "/v1/config") {
      return json({ app_id: env.KEYAUX_APP_ID, version: env.APP_VERSION,
        discord_url: supportURL(env.DISCORD_URL), discord_username: env.DISCORD_USERNAME || "pekiscripter" });
    }
    if (path !== "/v1/challenge" && path !== "/v1/license/check") return json({ error: "not_found" }, 404);
    if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
    requireConfiguration(env);
    await rateLimit(request, env, now);
    const body = await readJSON(request);
    if (body.version !== env.APP_VERSION) throw new AuthError(426, "version_mismatch", "Update this custom Instagram build.");
    const device = await publicKey(body.public_key);
    if (path === "/v1/challenge") {
      if (typeof body.license_hash !== "string" || !/^[0-9a-f]{64}$/.test(body.license_hash)) {
        throw new AuthError(400, "bad_request", "Invalid license digest.");
      }
      const nonce = base64(crypto.getRandomValues(new Uint8Array(32))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
      const id = crypto.randomUUID();
      await env.DB.prepare(
        "INSERT INTO peki_auth_challenges (id, nonce, hwid, license_hash, version, expires_at) VALUES (?, ?, ?, ?, ?, ?)"
      ).bind(id, nonce, device.hwid, body.license_hash, body.version, now + CHALLENGE_SECONDS).run();
      return json({ success: true, app_id: env.KEYAUX_APP_ID, version: env.APP_VERSION,
        challenge_id: id, nonce, hwid: device.hwid, license_hash: body.license_hash, expires_in: CHALLENGE_SECONDS });
    }
    if (typeof body.key !== "string" || !body.key.length || body.key.length > 256 || /[\r\n\0]/.test(body.key)
        || typeof body.challenge_id !== "string" || !/^[0-9a-f-]{36}$/.test(body.challenge_id)) {
      throw new AuthError(400, "bad_request", "Invalid license request.");
    }
    // Atomic consume: a proof, including a failed one, can only be used once.
    const challenge = await env.DB.prepare(
      "DELETE FROM peki_auth_challenges WHERE id = ? AND expires_at > ? RETURNING *"
    ).bind(body.challenge_id, now).first();
    if (!challenge) throw new AuthError(401, "challenge_expired", "The login challenge expired. Please retry.");
    const licenseHash = await hashHex(body.key);
    if (challenge.hwid !== device.hwid || challenge.license_hash !== licenseHash || challenge.version !== body.version) {
      throw new AuthError(401, "bad_proof", "The login proof does not match this device and license.");
    }
    const signature = derToRaw(decode64(body.signature, 100));
    const message = proofMessage(env.KEYAUX_APP_ID, body.version, challenge, device.hwid, licenseHash);
    if (!await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, device.key, signature, encoder.encode(message))) {
      throw new AuthError(401, "bad_proof", "The device signature was not accepted.");
    }
    const providerBody = { key: body.key, client_name: "Peki Scripter iOS", hwid: device.hwid, domain: "" };
    // Verify first: do not create another activation on every launch/recheck.
    let allowed = await providerRequest("verify", providerBody, env, fetchImpl);
    if (!allowed) allowed = await providerRequest("activate", providerBody, env, fetchImpl);
    if (!allowed) throw new AuthError(403, "license_denied", "No access. This key was not accepted; contact the developer or buy a key.");
    return json({ success: true, authorized: true, app_id: env.KEYAUX_APP_ID,
      version: env.APP_VERSION, hwid: device.hwid, lease_seconds: LEASE_SECONDS });
  } catch (error) {
    const known = error instanceof AuthError;
    return json({ success: false, authorized: false, error: known ? error.code : "server_error",
      message: known ? error.message : "The license server could not complete this request.",
      discord_url: supportURL(env.DISCORD_URL) }, known ? error.status : 503);
  }
}

export default {
  fetch(request, env) { return handleRequest(request, env); },
  async scheduled(controller, env) {
    const now = Math.floor(Date.now() / 1000);
    await env.DB.batch([
      env.DB.prepare("DELETE FROM peki_auth_challenges WHERE expires_at <= ?").bind(now),
      env.DB.prepare("DELETE FROM peki_auth_rate_limits WHERE expires_at <= ?").bind(now),
    ]);
  },
};
