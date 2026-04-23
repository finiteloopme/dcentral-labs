# GCIP Magic-Link Sign-In Setup (v1)

This document covers the one-time bootstrap for the **v1 magic-link
authentication architecture** introduced by issue #60. It supersedes the
direct Cloud Run IAP setup that was used previously (and the multi-IDP plan
described in issue #59, which is now closed).

It assumes:

- The Argolis project `kunal-scratch` is already deployed with all Cloud Run
  services running (see `cloudbuild.yaml` / `make cloud-deploy`).
- A Cloud DNS managed zone exists in a **separate Argolis project** that you
  control (cross-project DNS pattern).

For background and architecture rationale, see issue #60 and its v1 scope
comment.

---

## Overview

```
                 dcoder.<base_domain>
                          │
                          ▼
       ┌───────────────────────────────────┐
       │  External HTTPS Load Balancer     │
       │  (kunal-scratch project)          │
       │                                   │
       │  URL map:                         │
       │   /login*       → opencode-login  │
       │   /__/auth/*    → opencode-login  │
       │   /*  (default) → opencode-web    │
       └───────────────────────────────────┘
              │                       │
              ▼                       ▼
        opencode-login           opencode-web
        (no IAP)                 (IAP via gcipSettings
                                  agent flow)
```

---

## Phase 0 — Prerequisites (~5 min)

### Required configuration values

Fill in these placeholders in `config.toml [default.dns]`:

| Field | Description | Example |
|---|---|---|
| `project_id` | Argolis project hosting the Cloud DNS managed zone | `dns-host-project` |
| `zone_name`  | GCP resource name of the managed zone (NOT the DNS name) | `kunall-demo-altostrat-com` |
| `base_domain`| Root DNS name of the zone with **trailing dot** | `kunall.demo.altostrat.com.` |
| `subdomain`  | Subdomain for the dCoder deployment | `dcoder` |

The full FQDN for the deployment is constructed as `<subdomain>.<base_domain>`,
e.g. `dcoder.kunall.demo.altostrat.com`.

To list available managed zones:

```bash
gcloud dns managed-zones list --project=<dns-project-id>
```

### Cross-project DNS IAM grant

The Cloud Build service account in `kunal-scratch` must be able to create A
records in the DNS-hosting project. Grant `roles/dns.recordSetEditor` on that
project:

```bash
PROJECT_NUMBER=$(gcloud projects describe kunal-scratch --format='value(projectNumber)')

# Cloud Build SA
gcloud projects add-iam-policy-binding <DNS_PROJECT_ID> \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role=roles/dns.recordSetEditor

# Default compute SA (used by cloudbuild deploy steps)
gcloud projects add-iam-policy-binding <DNS_PROJECT_ID> \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role=roles/dns.recordSetEditor
```

### Firebase public config

The opencode-login service needs Firebase public config values
(`apiKey`, `authDomain`). These are **browser-safe public values** —
security is enforced via authorized domain whitelisting in the Firebase
Console plus Firebase Security Rules, not via secrecy of the apiKey.

Get them from the Identity Toolkit admin API:

```bash
ACCESS_TOKEN=$(gcloud auth print-access-token)
curl -sH "Authorization: Bearer $ACCESS_TOKEN" \
     -H "x-goog-user-project: kunal-scratch" \
     https://identitytoolkit.googleapis.com/admin/v2/projects/kunal-scratch/config
```

The response contains `client.apiKey` and `client.firebaseSubdomain`. The
`apiKey` is for `FIREBASE_API_KEY`. The auth domain is
`<firebaseSubdomain>.firebaseapp.com`.

Set these as Cloud Build substitutions when triggering a deploy:

```bash
gcloud builds submit \
  --config=cloudbuild.yaml \
  --substitutions=_FIREBASE_API_KEY=AIza...,_FIREBASE_AUTH_DOMAIN=kunal-scratch.firebaseapp.com
```

Or add them to your shell/`.env` for local testing.

---

## Phase 1 — Enable GCIP magic-link sign-in (~2 min)

```bash
make cloud-setup-gcip-magiclink
```

This makes a single PATCH call to the Identity Toolkit Admin API:

```
PATCH https://identitytoolkit.googleapis.com/admin/v2/projects/kunal-scratch/config?updateMask=signIn.email
{
  "signIn": {
    "email": {
      "enabled": true,
      "passwordRequired": false
    }
  }
}
```

After this, magic-link email sign-in is enabled. **No OAuth providers are
configured** in v1 — only email link.

---

## Phase 2 — Set up DNS (~2 min)

```bash
make cloud-setup-dns
```

This:

1. Reserves a global IP `opencode-web-lb-ip` in `kunal-scratch` (if not already).
2. Reads DNS values from `config.toml [default.dns]`.
3. Creates (or updates) an A record in the cross-project zone pointing to the LB IP.

---

## Phase 3 — Provision LB resources (~10 min)

```bash
make cloud-setup-lb
```

This provisions:

- Google-managed SSL cert for the FQDN (provisioning is asynchronous and
  takes 10–15 min after DNS resolves).
- Two serverless NEGs (one per Cloud Run service: `opencode-web-neg` and
  `opencode-login-neg`).
- Two backend services:
  - `opencode-web-backend` — IAP-enabled (gcipSettings applied in Phase 4)
  - `opencode-login-backend` — public, no IAP
- URL map `opencode-url-map` with path-based routing:
  - `/login*` and `/__/auth/*` → `opencode-login-backend`
  - everything else (default) → `opencode-web-backend`
- Target HTTPS proxy `opencode-https-proxy` using the URL map + cert.
- Global forwarding rule `opencode-fwd-rule` (port 443, target=https-proxy,
  address=opencode-web-lb-ip).

The cert provisioning is async; watch its status with:

```bash
gcloud compute ssl-certificates describe opencode-web-cert --global \
  --project=kunal-scratch \
  --format='get(managed.status,managed.domainStatus)'
```

When status shows `ACTIVE`, the LB is ready to serve traffic.

---

## Phase 4 — Apply IAP gcipSettings (manual, one-time)

The agent-flow gcipSettings YAML is currently applied via a one-time manual
gcloud command. (`cmd_setup_lb` enables IAP but does NOT yet apply the YAML
because the binding requires the LB to be active and the apiKey to be known.)

This is the critical "agent-flow" pattern using `tenantIds: ["_<project_number>"]`:

```bash
PROJECT_NUMBER=$(gcloud projects describe kunal-scratch --format='value(projectNumber)')
SUBDOMAIN=dcoder                    # from config.toml
BASE_DOMAIN=kunall.demo.altostrat.com  # from config.toml (trailing dot stripped)

cat > /tmp/iap_gcip.yaml <<EOF
accessSettings:
  gcipSettings:
    tenantIds:
    - _${PROJECT_NUMBER}
    loginPageUri: https://${SUBDOMAIN}.${BASE_DOMAIN}/login
EOF

gcloud beta iap settings set /tmp/iap_gcip.yaml \
  --project=kunal-scratch \
  --resource-type=backend-services \
  --service=opencode-web-backend
```

**Important note:** the `_${PROJECT_NUMBER}` tenantId pattern (underscore +
project number) is undocumented in public IAP docs but was empirically
validated by pilot session `/tmp/pilot-gcip-orgpolicy-220993ee`. It activates
the GCIP "agent flow" — project-scoped GCIP without requiring multi-tenancy.

---

## Phase 5 — Sync IAP IAM users (~1 min)

```bash
make cloud-sync-iap-users
```

This binds each user from `config.toml [default.auth].allowed_users` to
`opencode-web-backend` IAP IAM with `roles/iap.httpsResourceAccessor`. With
GCIP-issued tokens via the agent-flow pattern, IAP IAM works for ANY email
(not just Workspace-managed accounts).

---

## Verification

Visit `https://<subdomain>.<base_domain>` (e.g.
`https://dcoder.kunall.demo.altostrat.com`).

Expected flow:

1. Redirect to `/login` — URL bar stays on the same hostname.
2. Email input renders with dCoder branding.
3. Enter your email → "Check your email" message.
4. Click magic link in email → returns to `/__/auth/handler?...`.
5. Handler completes sign-in → redirects to original URL.
6. App loads (your email must be in `config.toml [default.auth].allowed_users`).

If sign-in fails at step 5, see "IAP+GCIP redirect-back" in the
"Open issues" section below.

---

## Rollback

To remove LB resources and revert to direct Cloud Run access:

```bash
make cloud-teardown-lb

# Optional: re-open Cloud Run services to public ingress
gcloud run services update opencode-web \
  --ingress=all --region=us-central1 --project=kunal-scratch
gcloud run services update opencode-login \
  --ingress=all --region=us-central1 --project=kunal-scratch
```

The DNS A record is left in place by `cloud-teardown-lb` (since it lives in a
different project). Delete it manually if needed:

```bash
gcloud dns record-sets delete dcoder.<base_domain>. --type=A \
  --zone=<zone-name> --project=<dns-project-id>
```

---

## Open issues / TODOs

### IAP+GCIP redirect-back contract

The `__/auth/handler.html` page currently uses a simple "redirect to original
URL" pattern after `signInWithEmailLink` succeeds. In some IAP+GCIP agent-flow
deployments, additional steps are required:

- POSTing the ID token to an IAP-specific endpoint, OR
- Relying on the Firebase JS SDK's automatic session-cookie behaviour (which
  requires `authDomain` to match the IAP-bound hostname).

If users complete sign-in but get bounced back to `/login` instead of seeing
the protected app, follow the IAP external-identities documentation:

- https://cloud.google.com/iap/docs/external-identities
- https://firebase.google.com/docs/auth/web/email-link-auth

The handler page documents this caveat inline.

### `cmd_setup_lb` does not apply gcipSettings

`cmd_setup_lb` enables IAP on `opencode-web-backend` but does not apply the
gcipSettings YAML. That step is currently manual (Phase 4 above). A future
enhancement is to extend `cmd_setup_lb` to construct and apply the YAML
automatically once the apiKey is available.

---

## Related

- Issue #60 — Migration tracking (this work)
- Issue #61 — Naming reconciliation (`opencode-web` vs `adk-backend`,
  resolved as part of #60 by standardizing cloudbuild on `opencode-web`)
- Issue #59 — Original cross-project Firebase plan (closed, superseded)
