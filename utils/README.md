# Run In Container Utility

`run-in-container.sh` is a versatile helper script that executes commands within a specified container environment using Podman. It eliminates the need to install and manage different language toolchains on your host machine, providing a clean, reproducible, and isolated environment for your development tasks.

## Features

- **Multiple Environments**: Pre-configured for common languages and tools like Go, Rust, Python, Node.js, and more.
- **Directory Mounting**: Automatically mounts your current working directory into the container, allowing you to work on your local files seamlessly.
- **Extensible**: Easily add new container images or pass custom arguments to Podman for advanced use cases.
- **Portable**: Place the script in your `PATH` to use it from anywhere in your system.

## Requirements

- **Podman**: The script is built on Podman and requires it to be installed and running on your system.

## Installation

You can install this script with a single command using either `curl` or `wget`. This will download the script directly to `/usr/local/bin` and make it executable, which requires `sudo`.

### Using `curl`

```bash
sudo curl -L https://raw.githubusercontent.com/finiteloopme/dcentral-labs/refs/heads/main/utils/run-in-container.sh -o /usr/local/bin/run-in-container.sh && sudo chmod +x /usr/local/bin/run-in-container.sh
```

### Using `wget`

```bash
sudo wget https://raw.githubusercontent.com/finiteloopme/dcentral-labs/refs/heads/main/utils/run-in-container.sh -O /usr/local/bin/run-in-container.sh && sudo chmod +x /usr/local/bin/run-in-container.sh
```

After installation, you can run the utility from any directory:

```bash
run-in-container.sh python --version
```

## Usage

The script is designed to be simple and intuitive.

```bash
run-in-container.sh <container_type> [command...]
```

-   `<container_type>`: A shorthand for the desired environment (e.g., `rust`, `python`).
-   `[command...]`: The command and its arguments to execute inside the container.

If no command is provided, the script will start an interactive `bash` shell inside the container.

### Available Container Types

-   `golang`: For Go development
-   `rust`: For Rust development
-   `python`: For Python development
-   `node`: For Node.js/JavaScript development
-   `debian`: A general-purpose Debian environment
-   `gcloud`: For Google Cloud CLI commands
-   `forge`: For Paradigm's Foundry (Solidity development)
-   `podman`: For building container images

### Basic Examples

```bash
# Check the installed Go version
run-in-container.sh golang go version

# Run a Python script
run-in-container.sh python my_script.py

# Get an interactive shell in a Node.js environment
run-in-container.sh node
```

## Advanced Usage

The script's power is unlocked via the `EXTRA_PODMAN_ARGS` environment variable, which allows you to pass any additional flags to the `podman run` command.

### Example 1: Cached Rust Builds

To speed up builds, you can mount your local Cargo cache directories into the container. This prevents dependencies from being re-downloaded on every run.

```bash
# Set the environment variable to mount the cargo registry and git caches
export EXTRA_PODMAN_ARGS="-v $HOME/.cargo/registry:/usr/local/cargo/registry -v $HOME/.cargo/git:/usr/local/cargo/git"

# Run the build command from your project's root directory
run-in-container.sh rust cargo build --release
```

### Example 2: Building Container Images (Podman-in-Podman)

You can build a `Dockerfile` by giving the `podman` container access to your host's Podman service.

1.  **Find your Podman socket path:**
    ```bash
    podman info --format '{{.Host.RemoteSocket.Path}}'
    ```

2.  **Set `EXTRA_PODMAN_ARGS` to mount the socket:**
    ```bash
    # Replace the path with the output from the command above
    export PODMAN_SOCKET=$(podman info --format '{{.Host.RemoteSocket.Path}}')
    export EXTRA_PODMAN_ARGS="-v $PODMAN_SOCKET:/run/podman/podman.sock"
    ```

3.  **Run the build:**
    ```bash
    # Run from the directory containing your Dockerfile
    run-in-container.sh podman build -t my-awesome-app .
    ```

### Example 3: Using the Google Cloud CLI (`gcloud`)

To use `gcloud` commands, you need to provide authentication credentials to the container. You can do this by mounting your local `gcloud` configuration directory, which is created after you authenticate locally.

1.  **Authenticate locally (if you haven't already):**
    ```bash
    gcloud auth application-default login
    ```

2.  **Set `EXTRA_PODMAN_ARGS` to mount the config directory:**
    ```bash
    # This makes your local gcloud credentials available inside the container
    export EXTRA_PODMAN_ARGS="-v $HOME/.config/gcloud:/root/.config/gcloud"
    ```

3.  **Run your `gcloud` command:**
    ```bash
    # Using the alias (recommended)
    gcloud projects list

    # Or without the alias
    run-in-container.sh gcloud gcloud projects list
    ```

## Pro-Tip: Transparently Containerize Toolchains

To make the integration completely seamless, you can create aliases that "wrap" the primary command for each toolchain. For better organization, it's a good practice to keep these aliases in a separate file and "source" it from your main shell configuration file.

**Step 1: Create a dedicated alias file**

Run the following command to create a file named `~/.oci_aliases` with all the recommended aliases.

```bash
cat << 'EOF' > ~/.oci_aliases
# --- Transparent Containerized Toolchains for run-in-container.sh ---
alias go='run-in-container.sh golang go'
alias cargo='run-in-container.sh rust cargo'
alias python='run-in-container.sh python python'
alias pip='run-in-container.sh python pip'
alias node='run-in-container.sh node node'
alias npm='run-in-container.sh node npm'
alias npx='run-in-container.sh node npx'
alias gcloud='run-in-container.sh gcloud gcloud'
alias forge='run-in-container.sh forge forge'
EOF
```

**Step 2: Source the alias file from your shell's config**

Add the following lines to the end of your `~/.bashrc` or `~/.zshrc` file. This will load your aliases automatically whenever you start a new shell.

```bash
# Load OCI aliases if the file exists
if [ -f ~/.oci_aliases ]; then
    . ~/.oci_aliases
fi
```

**Step 3: Reload your shell**

Open a new terminal window or run `source ~/.bashrc` (or `source ~/.zshrc`) to apply the changes. You can now use the commands like `go`, `cargo`, `gcloud`, etc., directly.

This method will "shadow" any native installations of these tools. If you need to run a native tool, you can bypass the alias by prefixing it with `command` (e.g., `command go version`).

## Extending the Script

You can easily add your own custom images by editing the `get_container_image` function in the script. Simply add a new case with a short name and the full image URL.
