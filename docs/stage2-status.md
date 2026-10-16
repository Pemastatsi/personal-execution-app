# Stage 2: isolated ChatGPT authentication proof of concept

Stage 2 is **not verified complete**. This branch implements the documented flow;
actual ChatGPT Plus sign-in and a completed, allowance-attributed inference need
an account holder and a physical Android device. No full application integration
has begun. No real OAuth token or inference request has been used in development.

## Eligibility and registration (checked 2026-10-16)

GitHub reports `Pemastatsi/personal-execution-app` as **public**. Main has no
open-source license. This PR proposes MIT in `LICENSE`, for owner review before
merging; public visibility alone does not grant an open-source license. The
published SIWC docs do not prescribe a particular license or list repository
popularity, minimum age, Android allowlisting, or a separate OSS partner approval
step. This is not evidence that OpenAI has approved this app or account.

The [official quickstart](https://developers.openai.com/siwc/quickstart) describes
plan usage for open-source partners and selected private clients. The
[OSS sign-in guide](https://developers.openai.com/siwc/token-sharing-open-source/sign-in)
documents first registration with `dynamic_agent_client`, then the **issued**
client ID for exchange and reauthorization, without a client secret or partner
API key. Registration and user/workspace consent occur in the system browser.
There is no borrowed Codex client ID, ChatGPT cookie, or backend-api route.

Remaining gates: owner review of licensing, actual registration acceptance,
granted `chatgpt.tokens.use.direct` permission, account-specific model access,
and successful subscription inference. If OpenAI returns a policy/eligibility
error, that is an actual admission blocker; it must not trigger a paid fallback.
Android is not expressly guaranteed by these docs. The prescribed
`http://127.0.0.1:<port>/auth/callback` must work in the device's browser and app
lifecycle before Android compatibility can be claimed.

## Existing subscription allowance only

Only an OAuth bearer token from the documented flow reaches the public
`/v1/models` and `/v1/responses` endpoints. No API-key configuration, separately
billed provider, credit purchase, top-up, paid fallback, or automatic inference
retry is present.

[OpenAI's billing-control guidance](https://help.openai.com/en/articles/20001542-using-your-chatgpt-plan-in-other-apps-and-sites)
states that app credit use is a separate opt-in, off by default. An app usage
limit **below 100% prevents credit use**, even if the account-level switch is on.
Before any inference, the user must keep app credit use off, save this app's limit
below 100%, then confirm the settings in the proof of concept. This confirmation
is memory-only and resets when the account changes or the app restarts.

The documented client API exposes **no way to inspect or set those billing
preferences, or to force allowance-only charging per request**. This app does not
claim it has remotely verified the settings. If the controls cannot be inspected
and saved for this registration, **do not enable Send**; allowance-only use remains
blocked. Do not buy credits or raise limits to solve eligibility or usage failures.
Any later external change to those settings invalidates the local confirmation.

## Implemented scope

- System-browser OAuth with loopback listener bound only to IPv4 loopback,
  five-minute timeout, cancellation, fresh cryptographic state/nonce/PKCE S256,
  exact callback/exchange URI, duplicate parameter rejection and issued-client
  binding. State is checked before any OAuth error or code is consumed.
- Pinned OpenAI OIDC discovery and JWKS origin, RS256 signature verification via
  `jose`, issuer/audience/authorized-party/expiry/nonce checks, and returning
  account subject matching. No unverified JWT identity is trusted.
- Separate account/workspace registrations keyed by issued client ID. The stable
  installation UUID host ID survives sign-outs. Secure v2 records keep identity,
  tokens, grant scopes and expiration together. The v1 scaffold's unvalidated
  credentials are deliberately not imported.
- PR #1's platform-secure-storage pattern, redacted errors, backup protection,
  and no plaintext fallback. Refresh is serialized and rotating tokens saved
  together before use. Terminal refresh errors clear tokens while preserving the
  registration mapping. Sign-out attempts revocation twice with bounded backoff,
  clears local tokens, and reports unconfirmed remote revocation.
- Scope verification before model discovery or inference. Catalog reads the
  documented `models` array, displaying only `visibility: list` entries and using
  their `slug`. No hardcoded production model.
- Stateless Responses HTTP/SSE using `store:false`, `stream:true`, and full local
  relevant conversation history. Only `response.completed` with completed status
  commits a turn. Failed/incomplete/malformed/interrupted streams discard partial
  output; no silent retries or alternate billing route.
- Basic in-memory text conversation with explicit Send, clearing, stop, and
  account isolation. The UI never imports local SQLite task records.
- Android system document picker for PNG/JPEG/WebP screenshots, five-MiB bounded
  reads, magic-byte checks, preview/removal and explicit confirmation before
  transmission. No broad storage or screenshot-capture permission. Unsupported
  image/model requests surface an error. No universal image-support claim.
- Windows supports the same text/authentication core and secure storage. Screenshot
  selection is scoped to the Android proof of concept and disabled on Windows.

## Automated validation vs. device evidence

Automated tests cover PKCE, callback rejection, cryptographically signed test
identities and claim/signature failures, local loopback OAuth with a fake OpenAI
server, granted-scope denial, account catalog filtering, mock secure resume and
rotation, concurrent refresh, revoked tokens, cancellation, SSE completion/failure,
credit-confirmation gating, widget accessibility and SQLite persistence. These
fixtures never contact OpenAI or consume the subscription. They do not prove
Android Keystore encryption, browser interoperability, account eligibility,
model capability, billing attribution or live inference.

Local Flutter analysis/tests cannot run because Flutter is absent and the
network policy denies `storage.googleapis.com` downloads. Required Flutter
analysis, tests and Android/Windows debug builds run through GitHub Actions.
Their actual outcomes are recorded in the PR after completion.

## Physical-device acceptance procedure

1. Review the license and install the current PR's Android debug APK from a
   successful **Flutter CI** run. Extract `app-debug.apk` from the artifact.
2. Tap **Continue with ChatGPT**. Sign in to the intended Plus account, select
   the workspace and authorize ChatGPT plan use. Return to the app. Check that
   the displayed registration matches and that account models load. A real
   callback, exchange, signed identity and granted scope must succeed.
3. Open **Manage usage**. Keep credit use OFF; save this app's usage limit below
   100%. Verify the saved values. If these controls are unavailable, leave Send
   disabled and record the exact restriction. Confirm settings in the app only
   after checking them. Never enable credit use or automatic purchases.
4. Select a listed model and send `Say exactly: Hello, world!`. Require a
   **Response completed** message, not just partial output. Check ChatGPT usage
   attribution for this app and verify no credits or API billing were used.
5. Select a small redacted screenshot, review it and explicitly send an analysis
   prompt. Record whether this particular model accepts it and completes.
6. Restart the app, select the saved registration and reload models. Recheck
   credit settings. After token expiry, confirm refresh works; check sign-out,
   remote revocation, reconnect and retained registration. Never paste tokens,
   authorization URLs, host IDs, or account details into public issues/logs.
7. Check browser cancellation, airplane mode, activity/process recreation,
   denied scope, unavailable/expired sessions and interrupted inference. Confirm
   draft/history isolation and no paid fallback after every failure.

Until steps 2–4 are actually observed, the user's success criterion is unmet.
