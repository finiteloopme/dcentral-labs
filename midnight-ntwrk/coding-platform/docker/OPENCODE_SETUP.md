# OpenCode TUI Setup for Midnight Workstation

OpenCode is a Terminal User Interface (TUI) application for AI-assisted coding that runs directly in your terminal.

## Quick Start

### 1. Get your Anthropic API Key
- Sign up at https://console.anthropic.com/
- Create an API key
- Copy the key (starts with `sk-ant-api...`)

### 2. Run the container with your API key

#### Using Podman:
```bash
# Navigate to docker directory
cd docker

# Build the image
podman build -t midnight-workstation:latest .

# Run with API key
ANTHROPIC_API_KEY='your-api-key-here' podman run -it --rm \
  --name midnight-local \
  --entrypoint /usr/local/bin/start-local \
  -p 8080:8080 \
  -p 8081:8081 \
  -e ANTHROPIC_API_KEY \
  midnight-workstation:latest
```

#### Or use the script:
```bash
# Set your API key
export ANTHROPIC_API_KEY='your-api-key-here'

# Run the container (it will detect the key)
./run-local-simple.sh
```

### 3. Use OpenCode in the terminal

1. Open Code OSS at http://localhost:8080
2. Open a terminal: `Terminal > New Terminal`
3. Run OpenCode:
   ```bash
   opencode
   ```

## OpenCode Commands

Once in OpenCode, you can:
- Ask questions about code
- Request code generation
- Get debugging help
- Refactor existing code

Example:
```
> How do I create a Midnight smart contract?
> Write a function to validate Ethereum addresses
> Explain this code: [paste code]
```

## Troubleshooting

### API Key not working?
```bash
# Check if key is set in container
echo $ANTHROPIC_API_KEY

# Set it manually if needed
export ANTHROPIC_API_KEY='sk-ant-api...'
```

### OpenCode not found?
```bash
# Check if installed
which opencode
npm list -g opencode-ai

# Reinstall if needed
npm install -g opencode-ai@latest
```

## Tips

- OpenCode remembers context within a session
- Use `exit` or Ctrl+D to quit OpenCode
- Your API key is never stored in the image, only passed at runtime
- For persistent config, mount a volume: `-v ~/.config/opencode:/tmp/user-home/.config/opencode`