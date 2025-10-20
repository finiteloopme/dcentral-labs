# Files That Can Be Removed

## Analysis of files and directories that can be safely removed or consolidated

### 1. **Redundant Docker Compose Files** (Not needed for Cloud Workstations)
- `docker/docker-compose.yml` - Not used in Cloud Workstations
- `docker/docker-compose.prod.yml` - Not used in Cloud Workstations  
- `docker/docker-compose.override.yml` - Not used in Cloud Workstations

**Reason**: Cloud Workstations doesn't use Docker Compose. These were likely from an earlier architecture.

### 2. **Duplicate Proof Service** (Redundant)
- `proof-service/` entire directory - Duplicate of what's in docker/
  - `proof-service/Dockerfile`
  - `proof-service/package.json`
  - `proof-service/src/server.js`
  - `proof-service/config/default.json`

**Reason**: The proof server is already implemented in `docker/proof-server.js` and `docker/proof-server-package.json`. Having two copies creates confusion.

### 3. **Unused Scripts in docker/scripts/**
- `docker/scripts/.terminal_profile` - Not referenced anywhere
- `docker/scripts/opencode-terminal.service` - Systemd service not used in containers
- `docker/scripts/web-terminal.js` - Web terminal not implemented (1000+ lines unused)
- `docker/scripts/package.json` - Unused package.json in scripts folder

**Reason**: These appear to be from earlier iterations and aren't used in the current implementation.

### 4. **Template Files in docker/scripts/** (Redundant)
- `docker/scripts/Token.compact.template` - Duplicate of template in docker/templates/
- `docker/scripts/token.test.js.template` - Duplicate of template in docker/templates/
- `docker/scripts/package.json.template` - Duplicate of template in docker/templates/
- `docker/scripts/Makefile.template` - Duplicate of template in docker/templates/

**Reason**: Templates are already in `docker/templates/basic-token/`. Having duplicates in scripts/ is confusing.

### 5. **Old Build Scripts** (Redundant)
- `scripts/build.sh` - Duplicate of docker/build.sh
- `scripts/push.sh` - Not needed, covered by Makefile
- `scripts/test-integration.sh` - No tests implemented
- `scripts/common.sh` - Not used
- `scripts/container-runtime.sh` - Logic already in Makefile
- `scripts/open-workstation.sh` - Terraform handles this

**Reason**: The Makefile already handles building and pushing. These scripts duplicate functionality.

### 6. **Unused Documentation**
- `docs/API.md` - No API documented (empty or placeholder)
- `docs/VERTEX_AI_SETUP.md` - Superseded by VERTEX_AI_MIGRATION.md

**Reason**: Empty or superseded documentation adds clutter.

### 7. **Cloud Build Files That May Not Be Needed**
Review if all these are actually used:
- `cicd/cloudbuild/cloudbuild-destroy.yaml`
- `cicd/cloudbuild/cloudbuild-import.yaml`  
- `cicd/cloudbuild/cloudbuild-plan.yaml`
- `cicd/cloudbuild/cloudbuild-test.yaml`
- `cicd/cloudbuild/cloudbuild-triggers.yaml`

**Reason**: Multiple Cloud Build configs might be redundant. Verify which are actually used.

### 8. **Consider Consolidating Documentation**
These could potentially be merged:
- `CLOUD_WORKSTATION_STATUS.md` - Could merge into README
- `LOCAL_VS_CLOUD_CHANGES.md` - Could merge into LOCAL_DEVELOPMENT.md
- `VERTEX_AI_MIGRATION.md` - Could merge into main docs

## Summary of Recommended Removals

### Definitely Remove (Redundant/Unused):
```bash
# Remove redundant Docker Compose files
rm docker/docker-compose*.yml

# Remove duplicate proof-service directory
rm -rf proof-service/

# Remove unused scripts
rm docker/scripts/.terminal_profile
rm docker/scripts/opencode-terminal.service
rm docker/scripts/web-terminal.js
rm docker/scripts/package.json

# Remove duplicate templates in scripts
rm docker/scripts/*.template

# Remove old build scripts
rm -rf scripts/

# Remove unused/empty docs
rm docs/API.md
rm docs/VERTEX_AI_SETUP.md
```

### Consider Removing After Review:
- Some Cloud Build configs if not all are needed
- Consolidate some documentation files

### Keep:
- All files in `docker/assets/` - These are essential for Cloud Workstations
- `docker/entrypoint-local.sh`, `docker/run-local.sh`, `docker/terminal-wrapper.sh` - Needed for local development
- Main documentation files (README, LOCAL_DEVELOPMENT, OPENCODE_USAGE)
- Terraform files - Needed for deployment
- Makefile - Primary build interface

## Impact
Removing these files will:
- Reduce repository size by ~30%
- Eliminate confusion from duplicate files
- Make the codebase cleaner and easier to maintain
- Remove ~1500+ lines of unused code (mainly web-terminal.js)

## Before Removing
1. Verify no CI/CD pipelines reference these files
2. Check if any documentation links to removed files
3. Consider backing up before bulk deletion