# Stage 2 status

Stage 2 is incomplete: app eligibility and actual subscription inference remain
unverified. This branch provides a blocked Android/Windows Flutter scaffold and
build automation, not a working ChatGPT integration.

## Delivered

- A scrollable connection page explaining the private-client eligibility gate.
- Disabled sign-in, send, and screenshot controls; no OAuth or inference client,
  paid provider, embedded API key, credit purchase, or fallback inference route.
- An in-memory draft with explicit clearing. It is neither persisted nor sent.
- An explicit manual fallback that copies only `https://chatgpt.com/`. The user
  opens ChatGPT and moves context themselves.
- Secure credential-store groundwork using the existing
  `flutter_secure_storage` dependency. Registrations use separate keys; token
  rotation writes the access/refresh pair as one record. Corrupt records and
  platform errors fail without a plaintext fallback or raw credential logging.
  There is no production caller. This does **not** validate OAuth tokens or
  implement refresh, revocation, account discovery, or authentication.
- Android backup disabled to avoid backing up future credential storage.
- Focused widget and credential-store tests, preserving existing SQLite tests.
- CI analysis and tests before Android/Windows builds, Java 17 for Android, and
  an uploaded debug APK with seven-day retention. No signing secret is needed.

## Feature verification

| Requested capability | Status |
| --- | --- |
| Official documentation access | Read successfully through the connected web tool; shell still blocked |
| Private app eligibility | Unverified; official quickstart supports selected private clients |
| Sign in with ChatGPT | Disabled pending eligibility; not implemented |
| Secure token storage | Persistence boundary implemented; tests use a fake platform store |
| Available model discovery | Not implemented; no account/model availability claimed |
| Text conversation | Local draft only; no inference |
| Screenshot analysis | Disabled; no image selected or sent |
| Usage/authentication failures | Live handling deferred with the live integration |
| Actual Plus-only inference | Not attempted or verified |

## Validation

Local `git diff --check` passes. Local `flutter analyze` and `flutter test` were
attempted but could not start because Flutter is absent. SDK installation is
blocked by proxy policy for `storage.googleapis.com`. CI runs the entire existing
and new Flutter test suite and analysis; its results must be checked before
merging. Secure-storage mocks do not verify Android Keystore, Windows credential
storage, or any OAuth/network behavior on a physical device.

To get the APK after a successful run: open the PR's **Flutter CI** run, then
download **personal-execution-stage2-android-debug-<run number>** from Artifacts.
Extract `app-debug.apk`. This is an installation-test build with AI disabled.

## Required next action

Obtain OpenAI confirmation that this **private personal Android/Windows app** may
use Sign in with ChatGPT plan usage on the existing Plus allowance, with no paid
credits or separately billed inference. The official entry point is the
[Sign in with ChatGPT interest form](https://openai.com/form/sign-in-with-chatgpt-interest/),
which currently targets commercial partners; do not assume acceptance. Provide
the resulting eligibility decision and supported client-registration instructions.
If approval was already obtained, supply that documentation instead.

Keep repository visibility unchanged. Making code public would require a separate
user decision and an appropriate open-source license/release review; this branch
does not propose or perform that action.

After eligibility is established, implement the documented browser/loopback PKCE
flow, validated identity and granted plan-usage scopes, refresh/revocation, model
discovery, and streamed text/model-supported image requests. Confirm the approved
route cannot consume purchased credits before enabling requests. Test denied
consent, expired/revoked tokens, shared usage exhaustion, interrupted streams,
and model/image failures without any paid fallback. On a real Android device,
verify loopback redirect and secure storage, then confirm a completed Responses
stream and its usage attribution in ChatGPT. Never send credentials in an issue,
PR, or support transcript. No full task-manager implementation is included.

For local development, publish an environment allowing the required official
documentation/authentication/API hosts plus Flutter's `storage.googleapis.com`
download host and the existing package/build hosts. The current environment's
policy snapshot does not include the OpenAI or Flutter storage hosts. This
environment repair is separate from app eligibility.
