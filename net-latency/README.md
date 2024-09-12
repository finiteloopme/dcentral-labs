
# Build

## Auth for Artifact Registry

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## Build on GCP

```bash
cargo clean
gcloud builds submit \
    --tag us-central1-docker.pkg.dev/gcda-apac-sc/container-demo/net-latency:latest
```

# Deploy

## Deploy to Cloud Run
```bash
declare -a regions=("us-central1")
for REGION in "${regions[@]}"
do
    echo ${REGION}
    # gcloud run services delete net-latency-${REGION} --region=${REGION}
    gcloud run deploy \
        net-latency-${REGION} \
        --image=us-central1-docker.pkg.dev/gcda-apac-sc/container-demo/net-latency:latest \
        --region=${REGION} \
        --set-env-vars "GCP_REGION=${REGION}" \
        --update-labels "app=net-latency" \
        --allow-unauthenticated
done
```

## Select Services
```bash
gcloud run services list --filter="metadata.labels.app=net-latency" --format="value[separator=','](name,status.url)"

```

## URL Encoding
```bash
_URL=https://relay-builders-direct-us.ultrasound.money:3000
echo ${_URL} | jq --slurp --raw-input --raw-output @uri
```

https://net-latency-us-central1-mo6u3xasea-uc.a.run.app/https%3A%2F%2Frelay-builders-direct-us.ultrasound.money%3A3000%0A/3
https://net-latency-us-central1-mo6u3xasea-uc.a.run.app/https%3A%2F%2Frelay-builders-direct-us.ultrasound.money%3A3000/3