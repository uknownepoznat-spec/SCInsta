# Peki Scripter → Cloudflare Worker → KeyAux

The Worker holds the KeyAux app secret. The IPA contains **no app/seller secret**.
KeyAux's own dashboard manages licenses, activations, HWID bindings and bans; this bridge exposes no Seller API or admin actions.

## Current deployment — 2026-11-21

- Worker: `https://peki-keyaux-bridge.uknownepoznat.workers.dev`
- Account: `6e392c9049397742bb244c88d86fa894`
- Dedicated D1 database: `peki-keyaux-state` (`8d339fa2-fcd7-4ea8-b3bb-52a62de3a10c`), Western Europe.
- Migration `0001_auth_state.sql` applied remotely; cleanup runs every 15 minutes.
- `RATE_LIMIT_PEPPER` was generated locally and uploaded directly as a Worker secret, without saving its value in project files.
- `KEYAUX_APP_SECRET` was entered through the official hidden Wrangler prompt and is present in Cloudflare. Its value was not read back or saved in the project.
- Live checks: `/v1/config` returns the expected app/version; real D1 challenges, invalid-signature rejection and one-use consumption passed.
- The initial provider-denial check exposed a Workers runtime incompatibility: `redirect: "error"` is unsupported. The local repair uses `manual` and explicitly rejects every 3xx response, without forwarding credentials.
- **2026-11-22:** the redirect repair is deployed as version `d44822d8-71ef-49d2-82e9-7cda4138a85a`. All 21 local tests pass, including a real workerd/local-D1 regression.
- The purchase invite update is deployed as version `9b208771-620b-4b8f-aa65-85ecedab908f`; public configuration now supplies `https://discord.gg/qTB3G7gCAp`.
- Live smoke checks pass against that deployment: expected public configuration, real D1 challenges, tampered-signature rejection, one-use consumption, signed nonexistent-license denial and replay rejection. These checks do **not** establish a successful valid-license login or prove that the entered secret was rotated.
- The public URL is configured in the native source.
- No plan upgrade, domain purchase, DNS change, or KeyAux license creation has been performed. An iPhone/native build and valid-license acceptance test are still required.

The following creation steps are for a **new deployment**. Do not recreate the database for the existing deployment; use its configured bindings for updates. To deploy to another account, change the public `account_id` and use a new D1 database ID in `wrangler.toml`.

## First: rotate the exposed secret

Regenerate the app secret in KeyAux App Settings. The old secret pasted into the conversation is **not used or saved in this project**. Do not paste its replacement into chat, GitHub, the iOS source, `wrangler.toml`, or screenshots.

## 1. Create a new Worker/D1 deployment

Install Node.js 24 and use a **new, dedicated D1 database**, not an existing application's database.

```sh
cd server/keyaux-worker
npm ci
npx wrangler login
npx wrangler d1 create peki-keyaux-state
```

Copy the returned `database_id` into `wrangler.toml`. The public App ID, Owner ID and version are already populated. The Client API authenticates by app secret; the Owner ID is informational and is not an administrative credential.

```sh
npx wrangler d1 migrations apply peki-keyaux-state --remote
npx wrangler deploy
npx wrangler secret put KEYAUX_APP_SECRET
npx wrangler secret put RATE_LIMIT_PEPPER
```

The first prompt receives your **new rotated** KeyAux secret. The second receives a fresh, random secret of at least 32 characters. Generate that locally, for example:

```sh
node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"
```

Never put either secret in source control. `.dev.vars.example` is a placeholder template for local testing, not real configuration.

`DISCORD_URL` in `wrangler.toml` is set to `https://discord.gg/qTB3G7gCAp`. The minimal native screen also opens this exact invite through `SCILicenseConfig.supportURL`, so purchasing does not depend on successfully fetching the Worker configuration.

```sh
npm test
npm run deploy
```

For the existing deployment, `npm run deploy` updates only this Worker and its configured bindings/triggers. Cloudflare login was authorized through Firefox with Workers-script/D1 access; OAuth credentials are stored encrypted with Windows Credential Manager, outside the project.

## 2. Configure and build the IPA

The current public Worker URL is already set in `src/License/SCILicenseConfig.m`. If moving to another backend, edit **only the public root HTTPS URL** and keep its App ID/version aligned with the Worker.

Use the **Build and Package SCInsta** / sideload workflow for LiveContainer, not a rootless `.deb`. Upload the whole changed project, including new `src/License/` and `server/keyaux-worker/` files.

Production defaults to `LICENSE_REQUIRED=1`. An unset server URL, missing secrets, unavailable network, invalid response or unsupported device key **does not unlock** a recognized guest window.

For the owner's local development only, an explicit `make LICENSE_REQUIRED=0` restores the old unlocked behavior. Do not distribute such a build. There is no in-app bypass switch or magic license.

## 3. Approve a phone and issue a license

1. In KeyAux → Licenses, generate a test key. Set a suitable duration, **Max Activations = 1**, and keep HWID locking enabled.
   Leave **Allowed IPs** and **Allowed Domains** empty for this integration: KeyAux sees the Worker's outbound IP, not a direct request from the phone. Do not rely on per-phone IP binding through this proxy.
2. Launch the rebuilt guest IPA in LiveContainer. The **Peki Scripter V2** screen shows `Enter your licence` and `Activate`.
3. Enter the generated **license key** and activate. With a fresh, unbound one-activation license, the first successful device becomes bound by KeyAux; issue the key only to its intended recipient.
4. Secure Enclave key creation must work in the exact LiveContainer/signing setup. If it fails, the screen shows a short error; it does **not** fall back to a fake IMEI or software UUID.
5. Manage the resulting activation/HWID in KeyAux. The fingerprint is not a serial/IMEI/UDID and is no longer printed on the login screen.
6. Test subsequent launches, expiry, bans and wrong-device activation before distributing.

The minimal login screen intentionally has no device-code, retry-saved, forget or diagnostics controls. Saved licenses still restore automatically through ThisDeviceOnly Keychain storage; this UI simplification does not reset the device key or a server activation. `V2` is UI branding, not a change to the KeyAux app version.

## Protocol and security boundaries

- Native iOS creates a permanent **P-256 Secure Enclave key**, protected with `WhenUnlockedThisDeviceOnly`. It never exports the private key.
- Worker challenges bind a random nonce to the app, version, public-key fingerprint and license digest. Challenges expire after 90 seconds and are atomically consumed once using D1.
- The app constructs the fixed protocol locally and signs it. The Worker verifies the P-256 signature before contacting KeyAux.
- KeyAux gets only the license credential, a fixed client label and the proved key fingerprint as `hwid`. No Instagram credentials, messages, IMEI or serial are sent.
- The Worker verifies an existing activation first; only a negative verification attempts activation. Unknown/malformed provider responses and upstream outages fail closed.
- Successful checks grant at most **300 seconds in active-app memory**, using monotonic uptime, not a saved `isAuthorized` preference. Foreground return requires an online recheck.
- Rate limiting uses a salted IP hash; keys, provider sessions and app secrets are not logged or returned to the client. Provider redirects are refused.
- Keychain items can become inaccessible after container/access-group/signing changes, reinstall/reset or device replacement. Preserve the guest's data and keychain group when updating. Lost keys require an administrator to reapprove/reset the binding.
- If KeyAux cannot reset a license's consumed usage/binding as needed, revoke the old activation/license and issue a replacement key. The app does not attempt administrative resets.
- **Proof of possession is not hardware attestation.** The server verifies a signature; it cannot independently certify that an arbitrary client created its key in Secure Enclave without an additional attestation scheme.
- A modified/repacked IPA can bypass local UI checks. This is licensing/access control for the custom client, **not unbreakable DRM**.
- Window covers apply to recognized Instagram-owned windows, never LC launcher roots. Test the exact guest/window lifecycle; an unrecognized Instagram root requires an adapter before release. Instagram may continue background network activity beneath the access screen.

## Provider contract used

Checked on 2026-11-21 against KeyAux's public dashboard documentation code:

- `https://dash.keyaux.com/js/api.js` supplies the base `https://service.keyaux.com`.
- `https://dash.keyaux.com/js/app.js`, Client API documentation, defines:
  - `POST /api/v1/licenses/verify`
  - `POST /api/v1/licenses/activate`
  - `X-App-Secret`, body `{ key, client_name, hwid, domain }`.
- The adapter requires a boolean `success` and a successful HTTP status. It does not forward provider response payloads or session tokens.

The secret from the conversation was not copied into requests or source. The user-entered secret is stored only in Cloudflare; its rotation cannot be independently verified. Live signed requests with random nonexistent licenses are correctly denied. A **successful valid-license login** still needs testing using a new test license and the rebuilt guest IPA.

## Tests and deployment checks

```sh
npm ci
npm test
```

Protocol tests use real WebCrypto signatures and an in-memory D1 double. A separate integration test runs the actual Worker inside workerd with real local D1 and a mocked provider, covering runtime fetch compatibility, one-use SQL consumption and redirect rejection. Neither test uses live secrets or an iPhone.

After deployment, run `npm run smoke` for live configuration, signed-proof/replay and invalid-license checks. It sends a disposable software public key and a random nonexistent license to the configured Worker. It does not read the app secret or create a valid license, and does not prove a valid phone license works.

On device, also verify:
- A missing/unreachable Worker never unlocks; neither does an arbitrary key.
- First login and a cold foreground return succeed with the approved device.
- Rechecks do not consume another activation.
- Bans/revocations deny the next check (at foreground or within five minutes).
- Wrong-device public keys and copied device codes alone do not pass proof verification.
- Keyboard, rotation, scenes, stories/modals, app-switcher transitions and LC launcher return do not expose an unintended bypass or cover the host launcher.
- Secure Enclave/Keychain access and saved-license restoration work in the exact signed LiveContainer build.
