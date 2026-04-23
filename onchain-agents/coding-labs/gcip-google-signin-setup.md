# GCIP Google Sign-In Setup (v2)

This document covers the operator-side setup for Google sign-in via the
LB+IAP+GCIP architecture. Replaces the abandoned email-link approach
(`gcip-magiclink-setup.md`) due to a Firebase backend bug for
`IDENTITY_PLATFORM` subtype projects.

## Architecture

```
[Browser] → IAP → /login → "Sign in with Google" button
                                ↓
                           signInWithPopup(GoogleAuthProvider)
                                ↓
                           GCIP routes to configured Google IdP
                                ↓
                           OAuth client in non-Argolis project
                           (External user type)
                                ↓
                           User signs in with Google account
                                ↓
                           Firebase ID token returned
                                ↓
                           IAP detects GCIP session via cookies
                                ↓
                           User redirected to protected app, signed in
```

## One-Time Setup

### Phase 1 — Provision OAuth Client in non-Argolis project (~10 min)

The Google OAuth Web Client must come from a project where the OAuth Consent
Screen has User Type: **External**. Argolis projects (`*.altostrat.com` org)
lock User Type to **Internal**. Therefore, use a non-Argolis Google account
or project.

**Steps:**

1. Sign in to https://console.cloud.google.com with a non-Argolis Google
   account (personal `@gmail.com` works)
2. Create new GCP project (or use existing): suggested name `dcoder-oauth-shim`
3. Configure OAuth Consent Screen:
   - APIs & Services → OAuth consent screen
   - User Type: **External**
   - App name: `dCoder`
   - User support email + developer contact: your email
   - Add **test users**: yourself + any whitelisted users (required while
     publishing status is "Testing")
4. Create OAuth 2.0 Web Client:
   - APIs & Services → Credentials → Create credentials → OAuth client ID
   - Application type: **Web application**
   - Name: `dCoder GCIP Bridge`
   - Authorized JavaScript origins: `https://kunal-scratch.firebaseapp.com`
   - Authorized redirect URI: `https://kunal-scratch.firebaseapp.com/__/auth/handler`
5. Capture **Client ID** and **Client Secret** (paste into Phase 2)

### Phase 2 — Configure Google IdP in GCIP (~30 sec)

```bash
ACCESS_TOKEN=$(gcloud auth print-access-token)
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "x-goog-user-project: kunal-scratch" \
  -H "Content-Type: application/json" \
  "https://identitytoolkit.googleapis.com/admin/v2/projects/kunal-scratch/defaultSupportedIdpConfigs?idpId=google.com" \
  -d '{
    "enabled": true,
    "clientId": "<CLIENT_ID_FROM_PHASE_1>",
    "clientSecret": "<CLIENT_SECRET_FROM_PHASE_1>"
  }'
```

Verify:

```bash
ACCESS_TOKEN=$(gcloud auth print-access-token)
curl -sH "Authorization: Bearer $ACCESS_TOKEN" \
  -H "x-goog-user-project: kunal-scratch" \
  "https://identitytoolkit.googleapis.com/admin/v2/projects/kunal-scratch/defaultSupportedIdpConfigs/google.com"
```

Expected: `enabled: true`, `clientId: <client-id>`, no secret in response.

### Phase 3 — Deploy `opencode-login`

```bash
make cloud-deploy
```

(or just opencode-login if granular target exists)

### Phase 4 — Verify end-to-end

1. Open `https://dcoder.kunall.demo.altostrat.com/` in incognito
2. IAP redirects to /login → "Sign in with Google" button visible
3. Click button → Google account picker popup appears
4. Sign in with a Google account that's in `config.toml allowed_users`
5. Popup closes, redirected to protected app, signed in

## Why the Cross-Project OAuth Client?

Google OAuth credentials require the OAuth Consent Screen to have User Type:
External. Argolis projects (`kunall.altostrat.com` org) lock the User Type
to Internal — there's no UI or API path to flip it. Pilot sessions extensively
confirmed this. Therefore, the OAuth client must come from a non-Argolis
project.

The cross-project dependency is a single Web OAuth client credential — much
smaller than maintaining a full Firebase Auth tenant in another project.

## What Was Wrong with Email-Link Sign-In?

We initially tried email-link sign-in (the magic-link approach). After
extensive debugging, we identified a Firebase backend bug for
`IDENTITY_PLATFORM` subtype projects: the email-link template's `%LINK%`
substitution produces empty host (`http://?apiKey=...`) despite all documented
prerequisites being correctly configured. The IdTk Admin API has no field
to customize the email-link sign-in template (only password reset / email
verify / change email templates are exposed), and tenant-level config is
gated for IDENTITY_PLATFORM projects. We pivoted to Google sign-in as the
unblock. See issue #67 for the full investigation.

## Rollback

To revert to email-link (not recommended due to the Firebase bug):

1. `git revert` the PR that landed this change
2. Run `make cloud-deploy`
3. Live with the broken email links until Firebase fixes the bug

---

## Related

- Issue #67 — Pivot to Google sign-in (this work)
- Issue #60 — Original LB+IAP+GCIP magic-link migration (superseded by #67 for
  the IdP choice; LB+IAP+GCIP plumbing remains as configured)
- PR #62 — LB+IAP+GCIP magic-link implementation
- PR #64 — Bootstrap LB+IAP+GCIP prerequisites + Firebase config emission
