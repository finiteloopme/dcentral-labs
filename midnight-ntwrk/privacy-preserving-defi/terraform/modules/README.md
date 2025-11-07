# Terraform Modules

This directory contains the modular Terraform configuration for the Privacy-Preserving DeFi infrastructure.

## Module Structure

```
modules/
├── services/      # GCP services and API enablement
├── networking/    # VPC, subnet, and firewall configuration
├── iam/          # Service accounts, workload identity, and permissions
└── compute/      # Virtual machines for mock server and TEE service
```

## Module Dependencies

```
main.tf
├── services (no dependencies)
├── networking (depends on: services)
├── iam (depends on: services)
└── compute (depends on: services, networking, iam)
```

## Module Descriptions

### Services Module
- **Purpose**: Enables required Google Cloud APIs and services
- **Resources**: `google_project_service` for compute, artifact registry, secret manager, IAM, etc.
- **Dependencies**: None

### Networking Module
- **Purpose**: Creates VPC, subnet, and firewall rules
- **Resources**: VPC network, subnetwork, firewall rules
- **Dependencies**: Services module (for compute API)

### IAM Module
- **Purpose**: Creates service accounts, workload identity pool, and permissions
- **Resources**: Service accounts, workload identity, artifact registry, IAM bindings
- **Dependencies**: Services module (for IAM, secret manager APIs)

### Compute Module
- **Purpose**: Creates virtual machines for application deployment
- **Resources**: Mock server VM, TEE service VM with confidential computing
- **Dependencies**: Services, networking, and IAM modules

## Usage

The modules are called from the root `main.tf` file with proper dependency management:

```hcl
# Enable required GCP services
module "services" {
  source = "./modules/services"
  gcp_project = var.gcp_project
}

# Create VPC and networking resources
module "networking" {
  source = "./modules/networking"
  # ... variables
  depends_on = [module.services]
}

# Create IAM and service account resources
module "iam" {
  source = "./modules/iam"
  # ... variables
  depends_on = [module.services]
}

# Create compute instances
module "compute" {
  source = "./modules/compute"
  # ... variables
  depends_on = [
    module.services,
    module.networking,
    module.iam
  ]
}
```

## Benefits of Modular Structure

1. **Separation of Concerns**: Each module handles a specific infrastructure component
2. **Reusability**: Modules can be easily reused in different environments
3. **Maintainability**: Easier to update and manage individual components
4. **Testing**: Modules can be tested independently
5. **Readability**: Clear organization and dependency management