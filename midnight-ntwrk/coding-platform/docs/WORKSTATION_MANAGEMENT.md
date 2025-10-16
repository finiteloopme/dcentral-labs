# Workstation Management Guide

The `workstation.sh` script provides comprehensive management of Cloud Workstations, allowing you to control workstations independently of the main deployment process.

## Quick Start

```bash
# List all workstations
./scripts/workstation.sh list

# Start the default workstation
./scripts/workstation.sh start

# SSH into workstation
./scripts/workstation.sh ssh

# Set up port forwarding
./scripts/workstation.sh port-forward
```

## Command Reference

### Global Options

These options can be used with any command:

```bash
--project-id PROJECT    # GCP project ID
--region REGION        # GCP region (default: us-central1)
--env ENV             # Environment name (default: mvp)
--workstation ID      # Workstation ID (default: midnight-developer-1)
--help, -h           # Show help message
```

### Commands

#### list
List all workstations in the current project.

```bash
./scripts/workstation.sh list
./scripts/workstation.sh list --env production
```

#### status
Show detailed status of a workstation.

```bash
./scripts/workstation.sh status
./scripts/workstation.sh status my-workstation
```

#### create
Create a new workstation.

```bash
./scripts/workstation.sh create my-new-workstation
./scripts/workstation.sh create test-ws --env staging
```

#### start
Start a workstation and get its URL.

```bash
./scripts/workstation.sh start
./scripts/workstation.sh start my-workstation
```

#### stop
Stop a running workstation.

```bash
./scripts/workstation.sh stop
./scripts/workstation.sh stop my-workstation
```

#### restart
Restart a workstation (stop and start).

```bash
./scripts/workstation.sh restart
./scripts/workstation.sh restart my-workstation
```

#### delete
Delete a workstation permanently.

```bash
./scripts/workstation.sh delete my-workstation
# Requires confirmation
```

#### ssh
SSH into a workstation.

```bash
# Interactive shell
./scripts/workstation.sh ssh

# Run specific command
./scripts/workstation.sh ssh my-workstation "ls -la /workspace"

# Custom bash command
./scripts/workstation.sh ssh --workstation dev-ws "cd /workspace && make test"
```

#### port-forward
Set up port forwarding for local development.

```bash
# Forward default ports (3000 for app, 8080 for proof service)
./scripts/workstation.sh port-forward

# Specific workstation
./scripts/workstation.sh port-forward my-workstation
```

Once running:
- Access app at http://localhost:3000
- Access proof service at http://localhost:8080

#### logs
View workstation logs.

```bash
./scripts/workstation.sh logs
./scripts/workstation.sh logs my-workstation
```

#### info
Show detailed information about workstation, configuration, and cluster.

```bash
./scripts/workstation.sh info
./scripts/workstation.sh info my-workstation
```

#### url
Get the workstation's web URL.

```bash
./scripts/workstation.sh url
./scripts/workstation.sh url my-workstation
```

#### update-config
Update workstation configuration to use the latest container image.

```bash
./scripts/workstation.sh update-config
# Then restart workstations to apply changes
```

## Common Workflows

### Development Workflow

```bash
# 1. Start workstation
./scripts/workstation.sh start

# 2. Set up port forwarding in another terminal
./scripts/workstation.sh port-forward

# 3. Access the IDE via browser (URL from step 1)
# 4. Access local app at http://localhost:3000

# 5. When done, stop the workstation
./scripts/workstation.sh stop
```

### Multiple Workstations

```bash
# Create workstations for different purposes
./scripts/workstation.sh create dev-frontend
./scripts/workstation.sh create dev-backend
./scripts/workstation.sh create test-integration

# List all workstations
./scripts/workstation.sh list

# Start specific workstation
./scripts/workstation.sh start dev-frontend

# SSH into specific workstation
./scripts/workstation.sh ssh dev-backend
```

### Team Collaboration

```bash
# Create workstations for team members
for member in alice bob charlie; do
    ./scripts/workstation.sh create "ws-$member"
done

# Check status of all workstations
./scripts/workstation.sh list

# Each member can start their own
./scripts/workstation.sh start ws-alice
```

### Debugging

```bash
# Check workstation status
./scripts/workstation.sh status my-workstation

# View detailed information
./scripts/workstation.sh info my-workstation

# Check logs for issues
./scripts/workstation.sh logs my-workstation

# Restart if having issues
./scripts/workstation.sh restart my-workstation
```

## Environment Variables

You can set defaults using environment variables:

```bash
export PROJECT_ID=my-gcp-project
export REGION=us-west1
export ENV=production
export WORKSTATION_ID=my-default-ws

# Now commands use these defaults
./scripts/workstation.sh start  # Uses all defaults above
```

## Integration with Make

The Makefile provides shortcuts for common operations:

```bash
make list          # List workstations
make start         # Start default workstation
make stop          # Stop default workstation
make ssh           # SSH into default workstation
make logs          # View logs
make port-forward  # Set up port forwarding
```

## Troubleshooting

### Workstation Won't Start

```bash
# Check cluster status
./scripts/workstation.sh info

# Check for errors in logs
./scripts/workstation.sh logs

# Try restarting
./scripts/workstation.sh restart
```

### Can't Connect via SSH

```bash
# Ensure workstation is running
./scripts/workstation.sh status

# Start if needed
./scripts/workstation.sh start

# Check firewall rules
gcloud compute firewall-rules list --project=$PROJECT_ID
```

### Port Forwarding Not Working

```bash
# Ensure workstation is running
./scripts/workstation.sh status

# Check if ports are already in use
lsof -i :3000
lsof -i :8080

# Kill existing processes if needed
kill $(lsof -t -i:3000)
kill $(lsof -t -i:8080)
```

### Performance Issues

```bash
# Check workstation configuration
./scripts/workstation.sh info

# May need to update machine type in Terraform
# Edit terraform/variables.tf to change machine_type
# Then redeploy: make deploy
```

## Best Practices

1. **Stop workstations when not in use** to save costs:
   ```bash
   ./scripts/workstation.sh stop
   ```

2. **Use meaningful names** for multiple workstations:
   ```bash
   ./scripts/workstation.sh create frontend-dev
   ./scripts/workstation.sh create backend-test
   ```

3. **Regular cleanup** of unused workstations:
   ```bash
   ./scripts/workstation.sh list
   ./scripts/workstation.sh delete old-workstation
   ```

4. **Monitor logs** for issues:
   ```bash
   ./scripts/workstation.sh logs --follow
   ```

5. **Update configuration** after container changes:
   ```bash
   make build push
   ./scripts/workstation.sh update-config
   ./scripts/workstation.sh restart
   ```

## Cost Optimization

Workstations incur costs when running. To minimize costs:

1. **Set appropriate idle timeout** in Terraform configuration
2. **Stop workstations** when not actively using them
3. **Use scheduled stop/start** for predictable work hours
4. **Monitor usage** with GCP billing reports

## Security Notes

- Workstations are accessed via IAP (Identity-Aware Proxy)
- No public IP addresses are assigned
- All traffic is encrypted
- Access is controlled by GCP IAM permissions

Ensure proper IAM roles:
```bash
# Grant workstation user access
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:email@example.com" \
    --role="roles/workstations.user"
```