# Stage 2 — Sign in with ChatGPT implementation reference

Research date: 2026-10-15. This note summarizes the official documentation; recheck the linked original sources when network access is restored. It is **not** proof that this repository, account, or Android build is eligible.

## Stage 2 verification update — 2026-10-15

Official pages were successfully read with the connected web tool. The cloud
shell still receives a proxy CONNECT 403 for `developers.openai.com`; this is
network policy, not an authentication rejection. `git pull --ff-only origin main`
succeeded with executor network access enabled.

The [official quickstart](https://developers.openai.com/siwc/quickstart) explicitly
limits plan usage to open-source partners and selected private clients. GitHub
metadata confirms this repository is private. No approval establishing that this
app is a selected private client is available. This is **unverified eligibility**,
not evidence that all private repositories are prohibited. A Plus subscription
alone does not establish app eligibility; leave live integration disabled.

The [request-client-ID page](https://developers.openai.com/siwc/request-client-id)
links to the [interest form](https://openai.com/form/sign-in-with-chatgpt-interest/)
for partner access. The form is aimed at commercial partners; acceptance of a
private personal app is not documented. Ask OpenAI whether this app qualifies
while remaining private and whether usage can be restricted to the existing Plus
allowance, with no purchased credits or other paid fallback. Do not submit
personal details or change repository visibility automatically.

The [session documentation](https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions)
states that Plus plan usage is shared across participating apps within a
five-hour limit. No separate per-app allowance should be assumed.

See [Stage 2 status](stage2-status.md) for delivered scope, testing, and the
remaining gates. No OAuth registration or inference request was attempted.

## Official primary sources
- Overview: https://developers.openai.com/siwc/token-sharing-open-source
- Registration and sign-in: https://developers.openai.com/siwc/token-sharing-open-source/sign-in
- Models and inference: https://developers.openai.com/siwc/token-sharing-open-source/models-and-inference
- Accounts/sessions: https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions
- Token reference: https://developers.openai.com/siwc/token-sharing-open-source/token-reference
- Preview limitations: https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations
- Errors and recovery: https://developers.openai.com/siwc/token-sharing-open-source/errors-and-recovery
- Cloud environment/network settings: https://learn.chatgpt.com/docs/environments/cloud-environments

## Confirmed flow to investigate and implement

1. Open-source, locally running clients can request **ChatGPT plan usage** as an optional permission in Sign in with ChatGPT. This permission does **not** provide existing ChatGPT conversations or hosted connector access. Eligibility for this particular **private** repository and account has **not been verified**.
2. Create/persist a distinct, opaque `ext_agent_host_id` for each installation before sign-in (supported `urn:uuid:<uuid-v4>`, among other documented formats). Use an actual app-name `agent_name_hint`.
3. On first registration use `client_id=dynamic_agent_client`, then retain the **issued** `client_id` returned from the callback. Use system browser, a loopback `http://127.0.0.1:<port>/auth/callback` receiver started before redirect, fresh state and nonce, and PKCE S256. Only callback **port** may change between attempts.
4. Request `openid profile email offline_access resource.invoke chatgpt.tokens.use.direct`, with `resource=https://api.openai.com/v1`. Exchange the code at `https://auth.openai.com/api/accounts/oauth/token` using the issued client ID, exact redirect URI, verifier, and resource. No client secret or paid API key.
5. Validate the ID token (JWKS signature, issuer, audience, expiry, nonce); ensure scope `chatgpt.tokens.use.direct` was actually granted. Keep each account registration and issued client ID separate; securely store and rotate refresh tokens.
6. Request `GET https://api.openai.com/v1/models` with the OAuth access token; select a model returned for the signed-in account. For inference use `POST https://api.openai.com/v1/responses` with bearer OAuth access token, `store:false`, `stream:true`, full relevant history in `input`, and wait for `response.completed` before success. Handle `response.failed`, interrupted streams, usage-limit errors.
7. Current preview accepts text and model-supported images/files, **not** audio transcription/video, image generation, hosted connectors, or native computer use. Many ordinary Responses parameters are unsupported; inspect the preview limitations list before building requests.
8. No separately billed API key, paid credits, or billing fallback is permitted. When plan usage is unavailable, maintain fully functioning offline task management and offer an explicit ChatGPT app fallback.

## Remaining validation gates
- Is this GitHub private repo eligible, or must code be published open source? Do not change visibility without user approval.
- Does this Android Flutter app successfully receive the documented loopback browser redirect on a real Android device?
- Does the user's actual account grant the plan usage scope and serve a successful streamed Responses request?
- Can the cloud runner build a test APK, and can user install and test it?
- No test passing with mocks is proof of real subscription inference.

## Cloud access workaround
The Codex environment has reported a proxy CONNECT 403 to official documentation. This source-checked reference allows preliminary offline implementation/review, but is not permission to invent or bypass unavailable documentation. Save/publish the environment domain allowlist separately; then start a **new** task and retest access. If proxy 403 persists, report it distinctly as proxy policy, not an OAuth failure.
