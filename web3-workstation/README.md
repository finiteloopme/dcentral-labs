# Web3 Development Workstation on Google Cloud

This project provides Terraform and Make automation to set up a complete Web3 development environment on Google Cloud Workstations.

It provisions a cloud-based workstation with a custom Docker image pre-loaded with essential Web3 tools like Foundry and Remix IDE. This allows for a consistent, powerful, and accessible development environment that you can connect to from anywhere.

## Prerequisites

Before you begin, ensure you have the following tools installed on your local machine:

-   [Google Cloud SDK (`gcloud`)](https://cloud.google.com/sdk/docs/install)
-   Terraform
-   Make
-   A Google Cloud Project with billing enabled.

## Setup Instructions

Follow these steps to configure and deploy your cloud development workstation.

### 1. Clone the Repository

```bash
git clone https://github.com/finiteloopme/dcentral-labs
cd web3-workstation
```

### 2. Configure Project Variables

Open the `Makefile` file and update the following variables with your Google Cloud project details:

```makefile
# Makefile

GCP_PROJECT_ID=<YOUR_GCP_PROJECT_ID>
GCP_REGION=<YOUR_GCP_REGION> # e.g., us-central1
# ... other variables can usually be left as default
```

Replace `<YOUR_GCP_PROJECT_ID>` with your actual Google Cloud Project ID and optionally change the `GCP_REGION`.

### 3. Authenticate with Google Cloud

Run the following command to authenticate your local environment with Google Cloud. This will also configure Docker to use your credentials for pushing to Google Artifact Registry.

```bash
make auth
```

This command will:
-   Log you into your Google Cloud account.
-   Set your default project and region for `gcloud`.
-   Configure Docker authentication for Artifact Registry.

### 4. Build and Push the Custom Docker Image

Next, build the custom development image and push it to your project's Artifact Registry. This image contains Foundry, Remix, and other necessary tools.

```bash
make build
```
This uses Cloud Build to build and push the image defined in the `src/` directory.

### 5. Deploy the Infrastructure

Now, use Terraform to provision the Google Cloud Workstation resources.

```bash
# Initialize Terraform (downloads providers)
make init

# Create an execution plan to see what will be created
make plan

# Apply the plan to create the resources
make apply
```

The `apply` command will prompt for confirmation before creating the workstation cluster, configuration, and the workstation instance itself.

## Accessing Your Workstation

Once the `make apply` command is complete, your workstation is ready.

1.  **Get connection details**:
    You can retrieve useful commands and information about your workstation by running:
    ```bash
    make output
    ```

2.  **Launch the Workstation**:
    Use the `workstation_launch_command` output from the previous step to start and connect to your workstation's IDE.

3.  **Access Remix IDE**:
    The Remix IDE runs on port 8080 inside the workstation. To access it from your local browser, you need to set up port forwarding. Use the `workstation_port_forward_command_remix` from the `make output` command.
    
    Once the tunnel is active, you can access Remix by navigating to `http://localhost:8080` in your local web browser.

## Cleanup

To avoid ongoing charges, you should destroy the cloud resources when you are finished.

**This is a destructive operation and will delete all resources created by Terraform.**

```bash
make destroy
```

You will be prompted for confirmation before the resources are deleted.
