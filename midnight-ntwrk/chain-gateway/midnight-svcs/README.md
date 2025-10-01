# midnight-mnn-helm
👉 Looking for the full architecture and configuration reference? Check **docs/OVERVIEW.md**.

# Requirement

To run a Midnight validator, you first need to be a Cardano SPO. This project only covers
new components required by the Midnight, and can be expanded to support Cardano SPO in the future.

- Become a Cardano SPO. Have the following keys `cold.skey`, `payment.vkey`, and `payment.skey` handy.
- Install Helm: https://helm.sh/docs/intro/install/

# Development

## Environment variables

The repo currently only uses the `testnet-02` variables from the docker compose repo in https://github.com/midnightntwrk/midnight-node-docker.

## Preview the change

```
helm template .
```

## Install the chart

Step 1: Create the `midnight` namespace
```
kubectl create namespace midnight
```

Step 2: Install the chart
```
helm install midnight-node . -n midnight
```

## Update the deployed chart

```
helm upgrade midnight-node . --namespace midnight
```

## Unstall the chart
```
helm uninstall midnight-node -n midnight
```

# Checking Cardano-db-sync Synchronization Progress

To check the synchronization progress of cardano-db-sync in Kubernetes:

```
kubectl exec -it $(kubectl get pods -n midnight -l app.kubernetes.io/component=postgres -o jsonpath='{.items[0].metadata.name}') -n midnight -- psql -U postgres -d cexplorer -c "SELECT 100 * (EXTRACT(EPOCH FROM (MAX(time) AT TIME ZONE 'UTC')) - EXTRACT(EPOCH FROM (MIN(time) AT TIME ZONE 'UTC'))) / (EXTRACT(EPOCH FROM (NOW() AT TIME ZONE 'UTC')) - EXTRACT(EPOCH FROM (MIN(time) AT TIME ZONE 'UTC'))) AS sync_percent FROM block;"
```

This will show you the synchronization progress as a percentage based on the time difference between the first and last block in the database compared to the current time.
