# GCIP Google Sign-In Setup (v3 — fully automated)

This document covers the operator-side setup for Google sign-in via the
LB+IAP+GCIP architecture. Replaces the manual Phase-by-Phase walkthroughs
of v1 (magic-link, abandoned per issue #67) and v2 (manual GCIP IdP setup,
consolidated in issue #69).

After issue #69 lands, all GCIP/IAP/LB configuration that used to be a
separate manual `curl`/`gcloud` invocation is automated by `scripts/cloud.sh`.
The operator only needs to populate two configuration values once
(`config.toml [default.auth.google].client_id` + `.env` `GOOGLE_OAUTH_CLIENT_SECRET`)
and then run three `make` commands.

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

## Operator Workflow After Issue #69

```bash
# One-time per environment
make cloud-setup        # Bootstraps project + DNS + LB + auth (chains 4 sub-targets)
make cloud-deploy       # Build + deploy services (auto-supplies Firebase substitutions)
make cloud-sync-users   # Bind whitelist from config.toml to IAP IAM

# Recurring as needed
make cloud-deploy       # Re-deploy code; no manual env-var fixes needed
make cloud-sync-users   # When whitelist changes
```

## One-Time Pre-Setup Steps

Before running `make cloud-setup`, complete these in order.

### Phase 0 — Create Google OAuth client in non-Argolis project (~10 min)

The Google OAuth Web Client must come from a project where the OAuth
Consent Screen has User Type: **External**. Argolis projects (`*.altostrat.com`
org) lock User Type to **Internal**. Therefore, use a non-Argolis Google
account or project.

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
     (substitute your IAP project's firebaseapp.com domain)
   - Authorized redirect URI: `https://kunal-scratch.firebaseapp.com/__/auth/handler`
5. Capture **Client ID** and **Client Secret** (used in Phase 1)

### Phase 1 — Populate `config.toml` + `.env`

Edit `onchain-agents/coding-labs/config.toml`:

- `[default.dns]` — `project_id`, `zone_name`, `base_domain`, `subdomain`
  (cross-project DNS managed zone)
- `[default.auth].allowed_users` — list of emails for IAP IAM
- `[default.auth.google].client_id` — paste the OAuth Client ID from Phase 0

Copy `.env.example` to `.env` and fill in:

- `GOOGLE_OAUTH_CLIENT_SECRET` — paste the OAuth Client Secret from Phase 0

`.env` is gitignored; `client_id` is public-by-design and safe to commit.

### Phase 2 — Cross-project DNS IAM grant

If the DNS zone lives in a separate project (typical for Argolis demos), the
DNS project owner must grant `roles/dns.recordSetEditor` on the DNS project to
both Cloud Build SAs in the IAP project. `make cloud-setup-project` (called
internally by `make cloud-setup`) attempts this and emits the manual `gcloud`
commands to share with the DNS owner if it lacks permission.

### Phase 3 — Run the bootstrap

```bash
make cloud-setup        # ~15 min (LB cert provisioning takes 10 min)
make cloud-deploy       # ~15 min (full multi-service Cloud Build pipeline)
make cloud-sync-users   # ~30 sec
```

`make cloud-setup` chains:

1. `cloud-setup-project` — APIs + project IAM (idempotent)
2. `cloud-setup-dns` — Cross-project A record from `[default.dns]`
3. `cloud-setup-lb` — NEGs + backend services + URL map + cert + IAP enable
4. `cloud-setup-auth` — Google IdP + authorizedDomains merge + IAP gcipSettings

Each sub-target is also runnable individually for surgical recovery, e.g.,
if the LB cert needs to be re-provisioned: `make cloud-setup-lb`.

`make cloud-deploy` auto-fetches the current Firebase apiKey from the
Identity Toolkit Admin API and passes it as `_FIREBASE_API_KEY` /
`_FIREBASE_AUTH_DOMAIN` Cloud Build substitutions. No manual `--substitutions`
flag is needed.

## Verification

After bootstrap completes, visit `https://<subdomain>.<base_domain>` (e.g.,
`https://dcoder.kunall.demo.altostrat.com`):

1. IAP redirects to `/login`
2. "Sign in with Google" button visible
3. Click → Google account picker popup
4. Sign in with a Google account that's in `[default.auth].allowed_users`
5. Popup closes, redirected to protected app, signed in

## Rollback

```bash
make cloud-teardown   # DESTRUCTIVE; removes all LB resources + Cloud Run services
```

(Cloud DNS records and the Artifact Registry repo are NOT touched.)

---

## Background

### Why the cross-project OAuth client?

Google OAuth credentials require the OAuth Consent Screen to have User Type:
External. Argolis projects (`kunall.altostrat.com` org) lock the User Type
to Internal — there's no UI or API path to flip it. Pilot sessions extensively
confirmed this. Therefore, the OAuth client must come from a non-Argolis
project.

The cross-project dependency is a single Web OAuth client credential — much
smaller than maintaining a full Firebase Auth tenant in another project.

### What was wrong with email-link sign-in (v1)?

We initially tried email-link sign-in (the magic-link approach). After
extensive debugging, we identified a Firebase backend bug for
`IDENTITY_PLATFORM` subtype projects: the email-link template's `%LINK%`
substitution produces empty host (`http://?apiKey=...`) despite all documented
prerequisites being correctly configured. The IdTk Admin API has no field
to customize the email-link sign-in template (only password reset / email
verify / change email templates are exposed), and tenant-level config is
gated for IDENTITY_PLATFORM projects. We pivoted to Google sign-in as the
unblock. See issue #67 for the full investigation.

### Why consolidate (v3, issue #69)?

After v2 (Google sign-in pivot), the operator workflow still required several
manual `curl` and `gcloud` invocations for:

- POSTing the Google IdP config to GCIP
- Merging `authorizedDomains` (preserving Firebase defaults)
- Applying the IAP `gcipSettings` YAML
- Re-supplying `_FIREBASE_API_KEY` substitutions on every deploy
- Patching the URL map path rules after handler.html was removed

Each manual step regressed on the next `make cloud-deploy`. Issue #69
codified all of these into `scripts/cloud.sh` so the operator never has to
reach for raw `gcloud`/`curl` again.

---

## Related

- Issue #69 — Consolidation (this rewrite)
- Issue #67 — Pivot to Google sign-in
- Issue #60 — Original LB+IAP+GCIP magic-link migration (LB plumbing remains;
  IdP changed to Google)
- PR #62 — LB+IAP+GCIP magic-link implementation
- PR #64 — Bootstrap LB+IAP+GCIP prerequisites + Firebase config emission
- PR #68 — Switch from email-link to Google OAuth (handler.html removed)
