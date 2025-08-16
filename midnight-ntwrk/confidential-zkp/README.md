
# Deploying Midnight Proof Server in a Confidential Space with TDX Attestation (Rust Edition)

This guide provides a comprehensive walkthrough for deploying a [Midnight proof server](https://docs.midnight.network/develop/tutorial/using/proof-server) within a [Google Cloud Confidential Space](https://cloud.google.com/confidential-computing/confidential-space/docs/confidential-space-overview).

This version uses a web server and client written in **Rust**.

The primary security goals are:

1. Ensure the Midnight proof server runs in a hardware-isolated, trusted execution environment (TEE).
2. Enforce that the TEE is specifically an Intel Trust Domain Extensions (TDX) environment through a verifiable attestation policy.
3. Provide a mechanism for an external user to cryptographically verify the remote attestation of the workload, confirming its integrity and environment.

## Project Structure

```bash
. 
├── attestation-client/ 
│   ├── Cargo.toml 
│   └── src/ 
│       └── main.rs 
├── attestation-server/ 
│   ├── Cargo.toml 
│   └── src/ 
│       └── main.rs 
├── Dockerfile 
├── README.md 
└── workload.yaml 
```

## Prerequisites

Before you begin, ensure you have the following:

1. **Google Cloud Project:** A Google Cloud project with billing enabled.
2. **gcloud CLI:** The [Google Cloud CLI](https://cloud.google.com/sdk/install) installed and authenticated.
3. **Rust:** The [Rust toolchain](https://www.rust-lang.org/tools/install) installed locally to run the client-side verification script.
4. **Permissions:** You'll need roles like Project Owner, Service Account Admin, Artifact Registry Administrator, Cloud Build Editor, and Compute Admin in your project.

## Step 1: Build and Push the Docker Image using Google Cloud Build

First, we will containerize the Midnight proof server and the Rust attestation server.

### 1.1. Create the Project Files

- Create the files in the directory structure specified above using the provided content for each file.
- Configure environment variables via `.env` file

   ```bash
   source .env
   ```

### 1.2. Set Up APIs and Artifact Registry

1. Enable the required APIs:

   ```bash
   gcloud services enable \
        artifactregistry.googleapis.com \
        cloudbuild.googleapis.com \
        compute.googleapis.com \
        confidentialcomputing.googleapis.com
   ```

2. Create a Docker repository:  

   ```bash
   gcloud artifacts repositories create $REPO_NAME --repository-format=docker --location=$REGION 
   ```

### 1.3. Build and Push the Image with Cloud Build

1. Set environment variables:

   ```bash
   export IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"
   ```

2. Submit the build to Google Cloud Build:

   ```bash
   gcloud builds submit --tag $IMAGE_URI . 
   ```

This command packages your entire directory, sends it to Cloud Build, and executes the build steps defined in the Dockerfile.

## Step 2: Configure IAM and Workload Identity

Set up a service account and a workload identity pool to securely verify the attestation claims.

### 2.1. Create a Service Account

```bash
gcloud iam service-accounts create $WORKLOAD_SA --display-name="Midnight Proof Server Workload SA"
```

### 2.2. Create a Workload Identity Pool and Provider

```bash
gcloud iam workload-identity-pools create $WIP_POOL --location="global" --display-name="Midnight Proof Server AP"
export _WIP_POOL_ID=$(gcloud iam workload-identity-pools describe $WIP_POOL --location="global" --format="value(name)")
export WIP_POOL_ID="${_WIP_POOL_ID##*/}" 
#echo $WIP_POOL_ID
gcloud iam workload-identity-pools providers create-oidc $WIP_PROVIDER \
    --workload-identity-pool=$WIP_POOL_ID \
    --location="global" \
    --issuer-uri="https://confidentialcomputing.googleapis.com/" \
    --allowed-audiences="https://sts.googleapis.com" \
    --attribute-mapping="google.subject=assertion.sub"
```

### 2.3. Grant Service Account Access

This policy ensures that only workloads running in a TDX environment can assume the service account's identity.

```bash
gcloud iam service-accounts add-iam-policy-binding "${WORKLOAD_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$WIP_POOL_ID/*"
```

## Step 3: Define and Deploy the Confidential Space Workload

### 3.1. Create a Firewall Rule

Create a firewall rule to allow external traffic to the Rust attestation server on port 8080.

```bash
gcloud compute firewall-rules create allow-attestation-server \
    --allow tcp:8080 \
    --target-tags=attestation-server \
    --description="Allow traffic to the attestation server"
```

### 3.2. Deploy the VM

1. **Important:** Update the your-gcloud-project-id placeholders in your workload.yaml file with your actual Project ID.
2. **Create the Confidential VM instance:**

   ```bash
   gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --machine-type="c3-standard-4" \
    --confidential-compute-type="TDX" \
    --image-family="confidential-space" \
    --image-project="confidential-space-images" \
    --metadata-from-file=user-data=workload.yaml \
    --service-account="${WORKLOAD_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --scopes="https://www.googleapis.com/auth/cloud-platform" \
    --tags=attestation-server \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any
    ```

## Step 4: Remote Attestation Verification with Rust Client

Verify the running workload from your local machine.

### 4.1. Run the Verification Script

1. **Get the external IP of your VM instance:** 

   ```bash
   export VM_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
   echo "VM External IP: $VM_IP"
   ```

2. **Navigate to the client directory and run it:** (It may take a minute or two for the server to initialize after the VM starts)

   ```bash
   cd attestation-client
   cargo run -- $VM_IP
   ```

The Rust client will fetch the token from your server, validate its signature against Google's public keys, and check the attestation claims.

## **Step 5: Cleanup**

To avoid incurring charges, delete the resources you created.

```bash
# Delete the Compute Engine instance
gcloud compute instances delete $INSTANCE_NAME --zone=$ZONE --quiet

# Delete the firewall rule
gcloud compute firewall-rules delete allow-attestation-server --quiet

# Remove the IAM policy binding from the service account
gcloud iam service-accounts remove-iam-policy-binding "${WORKLOAD_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://[iam.googleapis.com/$](https://iam.googleapis.com/$){WIP_POOL_ID}/attribute.tee_technology/TDX"

# Delete the service account
gcloud iam service-accounts delete "${WORKLOAD_SA}@${PROJECT_ID}.iam.gserviceaccount.com" --quiet

# Delete the Workload Identity Pool Provider
gcloud iam workload-identity-pools providers delete $WIP_PROVIDER \
  --workload-identity-pool=$WIP_POOL \
  --location="global" --quiet

# Delete the Workload Identity Pool
gcloud iam workload-identity-pools delete $WIP_POOL --location="global" --quiet

# Delete the container images from the repository
gcloud artifacts docker images delete $IMAGE_URI --delete-tags --quiet

# Delete the Artifact Registry repository
gcloud artifacts repositories delete $REPO_NAME --location=$REGION --quiet

echo "Cleanup complete."
```