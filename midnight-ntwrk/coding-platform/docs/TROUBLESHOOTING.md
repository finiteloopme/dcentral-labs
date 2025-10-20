# Troubleshooting Guide

## Accessing Code OSS on Cloud Workstations

### Primary Access Methods

#### 1. Browser Access (Recommended)
```bash
make ws-open
```
Opens Code OSS directly in your browser through the workstation URL.

#### 2. Local Tunnel
```bash
make ws-tunnel
```
Creates a tunnel from `localhost:8080` to the workstation's Code OSS.

#### 3. Cloud Console
Go to https://console.cloud.google.com/workstations and click "Open" on your workstation.

### Common Issues

#### Code OSS doesn't load in browser
- Ensure workstation is running: `make ws-start`
- Clear browser cache and cookies
- Try incognito/private browser mode
- Ensure you're logged into Google Cloud
- Use tunnel method instead: `make ws-tunnel`

#### Workstation not found
Deploy the infrastructure first:
```bash
make deploy
```

#### Tunnel connection fails
- Start the workstation: `make ws-start`
- Check IAM permissions (need `roles/workstations.user`)
- Try browser access instead: `make ws-open`

## Local Development Issues

### Container runs as root
For secure non-root mode:
```bash
make run-local-secure
```

### Code OSS not accessible at localhost:8080
Use `http://127.0.0.1:8080` instead (Code OSS binds to IPv4 only).

### Container won't start
Check ports aren't in use:
```bash
lsof -i :8080
lsof -i :8081
```

## Build Issues

### Cloud Build fails
Check logs:
```bash
make status
gcloud builds log <BUILD_ID>
```

### Permission denied in Cloud Build
Grant required roles to Cloud Build service account:
```bash
PROJECT_NUM=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com" \
  --role="roles/compute.admin"
```