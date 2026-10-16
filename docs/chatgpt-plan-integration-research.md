# Stage 2 — current official integration reference

Rechecked 2026-10-16. This supersedes the earlier private-repository blocker.
GitHub visibility is public. See [current Stage 2 status](stage2-status.md) for
remaining licensing, actual registration, billing-setting and physical-device
gates. Public visibility is evidence of source availability, not proof of an
open-source license or OpenAI account eligibility.

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

1. Open-source, locally running clients can request **ChatGPT plan usage** as an optional permission in Sign in with ChatGPT. This permission does **not** provide existing ChatGPT conversations or hosted connector access. Actual registration and account eligibility have **not been verified**.
2. Create/persist a distinct, opaque `ext_agent_host_id` for each installation before sign-in (supported `urn:uuid:<uuid-v4>`, among other documented formats). Use an actual app-name `agent_name_hint`.
3. On first registration use `client_id=dynamic_agent_client`, then retain the **issued** `client_id` returned from the callback. Use system browser, a loopback `http://127.0.0.1:<port>/auth/callback` receiver started before redirect, fresh state and nonce, and PKCE S256. Only callback **port** may change between attempts.
4. Request `openid profile email offline_access resource.invoke chatgpt.tokens.use.direct`, with `resource=https://api.openai.com/v1`. Exchange the code at `https://auth.openai.com/api/accounts/oauth/token` using the issued client ID, exact redirect URI, verifier, and resource. No client secret or paid API key.
5. Validate the ID token (JWKS signature, issuer, audience, expiry, nonce); ensure scope `chatgpt.tokens.use.direct` was actually granted. Keep each account registration and issued client ID separate; securely store and rotate refresh tokens.
6. Request `GET https://api.openai.com/v1/models` with the OAuth access token; select a model returned for the signed-in account. For inference use `POST https://api.openai.com/v1/responses` with bearer OAuth access token, `store:false`, `stream:true`, full relevant history in `input`, and wait for `response.completed` before success. Handle `response.failed`, interrupted streams, usage-limit errors.
7. Current preview accepts text and model-supported images/files, **not** audio transcription/video, image generation, hosted connectors, or native computer use. Many ordinary Responses parameters are unsupported; inspect the preview limitations list before building requests.
8. No separately billed API key, paid credits, or billing fallback is permitted. When plan usage is unavailable, maintain fully functioning offline task management and offer an explicit ChatGPT app fallback.

## Remaining validation gates
- Main still needs an owner-reviewed open-source license; this PR proposes MIT. No particular license is mandated in the reviewed SIWC docs.
- Does this Android Flutter app successfully receive the documented loopback browser redirect on a real Android device?
- Does the user's actual account grant the plan usage scope and serve a successful streamed Responses request?
- Can the cloud runner build a test APK, and can user install and test it?
- No test passing with mocks is proof of real subscription inference.

## Subscription-only safeguard

The [official credit-control guide](https://help.openai.com/en/articles/20001542-using-your-chatgpt-plan-in-other-apps-and-sites)
says app credit use requires explicit opt-in and an app limit of 100%; a lower
app limit prevents credit use. Keep credit use off and save this app's limit
below 100%. The documented API does not expose these settings, so local
confirmation cannot replace checking the saved ChatGPT preference.
