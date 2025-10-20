# Using OpenCode TUI in Local Development

## Prerequisites

1. **Set up Google Cloud credentials**:
   ```bash
   # On your host machine (not in container)
   gcloud auth application-default login
   ```

2. **Start the container**:
   ```bash
   make run-local
   ```
   
   The container will automatically mount your gcloud credentials from `~/.config/gcloud`

## Launching OpenCode

### From the Main Terminal

When you run `make run-local`, you're dropped into a terminal as `ubuntu` user:

```bash
ubuntu@midnight:~$ opencode
```

### From Code OSS Terminal

1. Open Code OSS at http://127.0.0.1:8080
2. Open a new terminal: Terminal → New Terminal
3. Launch OpenCode:
   ```bash
   ubuntu@localhost:~$ opencode
   ```

## Configuration

OpenCode is pre-configured to use Vertex AI with Claude 3.5 Sonnet. The configuration is stored in `/home/ubuntu/.config/opencode/config.json`:

```json
{
  "model": "vertex-ai/claude-3-5-sonnet@20241022",
  "context": "coding"
}
```

## Troubleshooting

### "Error: Failed to connect to Vertex AI"
Ensure you have:
1. Authenticated with gcloud on your host machine
2. Set up application default credentials:
   ```bash
   # On host machine
   gcloud auth application-default login
   ```
3. Restarted the container after authentication

### Terminal UI doesn't display properly
Make sure your terminal supports 256 colors:
```bash
echo $TERM  # Should show xterm-256color
```

### Can't navigate the TUI
OpenCode uses keyboard navigation:
- **Arrow keys**: Navigate menus
- **Enter**: Select options
- **Tab**: Switch between panes
- **Ctrl+C**: Exit

### OpenCode not found
Check if it's installed:
```bash
which opencode  # Should show /usr/bin/opencode
opencode --version  # Should show version number
```

### Vertex AI permission errors
Ensure your GCP project has the Vertex AI API enabled and your account has the necessary permissions:
```bash
# Check current project
gcloud config get-value project

# Enable Vertex AI API (if needed)
gcloud services enable aiplatform.googleapis.com
```

## OpenCode Commands

Once OpenCode is running:

1. **Start a chat**: Press Enter on "New Chat"
2. **Model selection**: Already configured for Claude 3.5 Sonnet via Vertex AI
3. **Type your query**: Describe what you want to code
4. **Get AI assistance**: Claude will help with your code

## Tips

1. **Use with your project**: Navigate to your project directory first:
   ```bash
   cd /home/ubuntu/my-project
   opencode
   ```

2. **Session management**: OpenCode saves sessions, use `--continue` to resume:
   ```bash
   opencode --continue
   ```

3. **Check Vertex AI configuration**:
   ```bash
   cat ~/.config/opencode/config.json
   ```

## Example Session

```bash
# In the container terminal
ubuntu@midnight:~$ cd /home/ubuntu/workspace
ubuntu@midnight:~/workspace$ opencode

# OpenCode TUI launches with Vertex AI/Claude
# Select "New Chat"
# Type: "Help me create a Midnight smart contract"
# Claude provides assistance via Vertex AI
```

## Important Notes

- OpenCode uses Vertex AI through your Google Cloud credentials
- Credentials are mounted read-only from your host machine
- The TUI needs a terminal with proper dimensions (resize if needed)
- Sessions are saved locally in the container at `~/.local/share/opencode/`
- No API keys are stored in the container image
- Vertex AI usage is billed to your GCP project