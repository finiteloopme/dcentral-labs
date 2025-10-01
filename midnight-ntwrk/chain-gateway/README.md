
# Midnight Node on GKE with Terraform and Helm

## Overview

This project provides a complete solution for deploying a Midnight Node, Proof Server, and Indexer Standalone on a GKE Autopilot cluster. It uses Terraform to manage the GKE cluster and a Helm chart to deploy the Midnight components.

## Prerequisites

Before you begin, ensure you have the following tools installed and configured:

*   [Podman](https://podman.io/)
*   [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud` and `gsutil`)

## Terraform

The Terraform configuration in this project is used to create and manage the GKE Autopilot cluster and an AlloyDB for PostgreSQL instance. The configuration is located in the `terraform` directory.

### GCS Backend

The Terraform state is stored in a GCS bucket. You will need to create a GCS bucket and update the `config.env` file with the name of the bucket.

1.  **Create a GCS bucket:**

    ```bash
    gsutil mb gs://your-gcs-bucket-name
    ```

2.  **Update the `config.env` file:**

    Update the `BUCKET_NAME` variable in the `config.env` file with the name of your GCS bucket.

### Usage

The following `make` targets are available for managing the Terraform infrastructure:

*   `make init`: Initializes Terraform and the GCS backend.
*   `make plan`: Creates a Terraform execution plan and uploads it to GCS.
*   `make apply`: Applies the Terraform configuration from the plan in GCS.
*   `make destroy`: Destroys the Terraform-managed infrastructure.

## Helm

The Helm chart in this project is used to deploy the `midnight-node`, `proof-server`, and `indexer-standalone` components. The chart is located in the `midnight-duo` directory.

### Usage

The following `make` targets are available for managing the Helm chart:

*   `make helm-init`: Configures `kubectl` to connect to the GKE cluster.
*   `make helm-generate-key`: Generates a new node key and updates the `values.yaml` file.
*   `make helm-apply`: Deploys or upgrades the Helm chart with the AlloyDB connection details.
*   `make helm-delete`: Deletes the Helm chart.

Before you can use the `helm-*` targets, you need to configure `kubectl` to connect to the GKE cluster by running `make helm-init`.

## Applying Changes to a Live Deployment

1.  **Run `make plan`:** Before applying any changes, it's crucial to run `make plan` to see what changes Terraform will make to your infrastructure. This will help you to identify any unexpected changes and to ensure that the changes are what you expect.

2.  **Review the plan:** Carefully review the output of the `make plan` command. Pay close attention to any resources that are planned to be destroyed or recreated. If you see any unexpected changes, you should investigate the cause before proceeding.

3.  **Apply the changes:** Once you are confident that the plan is correct, you can apply the changes by running `make apply`. This will update your infrastructure to match the new configuration.

4.  **Run `make helm-apply`:** After the infrastructure changes have been applied, you can update the Helm chart by running `make helm-apply`. This will deploy the new version of the application with the updated configuration.

### Important Considerations

*   **Backup your data:** Before applying any changes to a live deployment, it's always a good practice to back up your data. This will help you to recover your data in case something goes wrong.
*   **Maintenance window:** If possible, you should apply the changes during a maintenance window to minimize the impact on your users.
*   **Canary deployment:** For critical applications, you may want to consider using a canary deployment strategy. This involves deploying the new version of the application to a small subset of users before rolling it out to everyone. This will help you to identify any issues with the new version before it affects all of your users.

## Makefile

The `Makefile` provides a convenient way to manage the Terraform and Helm workflows. Here is a list of all the available targets:

*   `init`: Initializes Terraform.
*   `plan`: Creates a Terraform execution plan and uploads it to GCS.
*   `apply`: Applies the Terraform configuration from the plan in GCS.
*   `destroy`: Destroys the Terraform-managed infrastructure.
*   `helm-init`: Configures `kubectl` to connect to the GKE cluster.
*   `helm-generate-key`: Generates a new node key and updates the `values.yaml` file.
*   `helm-apply`: Deploys or upgrades the Helm chart with the AlloyDB connection details.
*   `helm-delete`: Deletes the Helm chart.
