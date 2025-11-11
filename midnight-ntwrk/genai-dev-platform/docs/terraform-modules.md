# Terraform Modules Structure

This Terraform configuration uses a modular architecture to organize resources logically and promote reusability.

## Module Structure

```
terraform/
├── main.tf                    # Main orchestration file (flow controller)
├── variables.tf               # Root module variables
├── outputs.tf                 # Root module outputs
├── terraform.tfvars.example   # Example variables file
└── modules/                   # Modules directory
    ├── api-services/          # Google Cloud API enablement
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── artifact-registry/     # Container registry
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── networking/            # VPC network and firewall
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── workstation/           # Workstation cluster and config
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── iam/                   # IAM permissions
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Module Descriptions

### 1. api-services
**Purpose**: Enables required Google Cloud APIs using a configurable list
- Default APIs: `workstations.googleapis.com`, `artifactregistry.googleapis.com`, `cloudbuild.googleapis.com`, `aiplatform.googleapis.com`, `vertexai.googleapis.com`
- Configurable via `services` variable
- Uses `for_each` loop for dynamic service enablement
- Includes Vertex AI and AI Platform APIs for AI features

### 2. artifact-registry
**Purpose**: Creates container registry for storing the platform image
- Creates Docker repository
- Configures repository settings
- Provides image URL for workstation module

### 3. networking
**Purpose**: Manages VPC network and firewall rules
- Creates VPC network
- Configures firewall rules for required ports
- Provides network references to workstation module

### 4. workstation
**Purpose**: Creates workstation cluster and configuration
- Deploys workstation cluster
- Configures workstation settings
- Sets up container and persistent storage

### 5. iam
**Purpose**: Manages IAM permissions
- Grants Cloud Build access to Artifact Registry
- Provides workstation access to specified users
- Configures Vertex AI and Model Garden access for service accounts
- Supports separate Vertex AI project configuration

## Module Dependencies

```
api-services (no dependencies)
    |
    v
artifact-registry (depends on api-services)
    |
    v
networking (no dependencies)
    |
    v
workstation (depends on artifact-registry, networking)
    |
    v
iam (depends on workstation, artifact-registry)
```

## Benefits of Modular Structure

1. **Separation of Concerns**: Each module handles a specific aspect of the infrastructure
2. **Reusability**: Modules can be reused in different environments or projects
3. **Maintainability**: Easier to update and maintain individual components
4. **Testing**: Modules can be tested independently
5. **Readability**: Clear organization makes the code easier to understand

## Usage

The main.tf file acts as the orchestrator, calling each module with the appropriate variables and passing outputs between modules as needed.

### Example Module Call

```hcl
module "api_services" {
  source     = "./modules/api-services"
  project_id = var.project_id
  services   = [
    "workstations.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com"  # Additional service example
  ]
}

module "workstation" {
  source                   = "./modules/workstation"
  project_id              = var.project_id
  region                  = var.region
  cluster_name            = var.cluster_name
  environment             = var.environment
  machine_type            = var.machine_type
  persistent_disk_size_gb = var.persistent_disk_size_gb
  image_url               = module.artifact_registry.container_image_url
  google_vertex_project   = var.google_vertex_project
  google_vertex_region    = var.google_vertex_region
  network_id              = module.networking.network_id
  subnetwork_id           = module.networking.subnetwork_id
}
```

## Customization

Each module can be customized independently:
- Modify variables in the module's `variables.tf`
- Update resource configurations in the module's `main.tf`
- Adjust outputs in the module's `outputs.tf`

## Best Practices

1. **Keep modules focused**: Each module should have a single responsibility
2. **Use descriptive names**: Module and variable names should be clear
3. **Document interfaces**: Variables and outputs should have clear descriptions
4. **Version control**: Tag module versions for production use
5. **Test modules**: Validate modules before integration