# Run In Container Utility

`run-in-container.sh` is a versatile helper script that executes commands within a specified container environment. It eliminates the need to install and manage different language toolchains on your host machine, providing a clean, reproducible, and isolated environment for your development tasks.

## Features

- **Multiple Runtimes**: Supports both **Podman** and **Docker** as container runtimes.
- **Built-in Defaults**: Comes with a pre-configured set of common container images, so it works out of the box.
- **Centralized Configuration**: A single `~/.utils/images.yaml` file for all your custom container images.
- **Dynamic Image Management**: Add or update container images in your `~/.utils/images.yaml` file directly from the command line.
- **Directory Mounting**: Automatically mounts your current working directory into the container, allowing you to work on your local files seamlessly.
- **Extensible**: Pass custom arguments to the container runtime for advanced use cases.
- **Portable**: Place the script in your `PATH` to use it from anywhere in your system.

## Requirements

- A container runtime: **Podman** (default) or **Docker**.

## Installation

You can install this script with a single command using either `curl` or `wget`. This will download the script directly to `/usr/local/bin` and make it executable, which requires `sudo`.

The script works out of the box with a default set of images. No additional configuration is required.

### Using `curl`

```bash
sudo curl -L https://raw.githubusercontent.com/finiteloopme/dcentral-labs/refs/heads/main/utils/run-in-container.sh -o /usr/local/bin/run-in-container.sh && sudo chmod +x /usr/local/bin/run-in-container.sh
```

### Using `wget`

```bash
sudo wget https://raw.githubusercontent.com/finiteloopme/dcentral-labs/refs/heads/main/utils/run-in-container.sh -O /usr/local/bin/run-in-container.sh && sudo chmod +x /usr/local/bin/run-in-container.sh
```

## Usage

The script is designed to be simple and intuitive.

```bash
run-in-container.sh [options] <container_type> [command...]
```

-   `[options]`: Optional flags to control the script's behavior.
-   `<container_type>`: A shorthand for the desired environment (e.g., `rust`, `python`).
-   `[command...]`: The command and its arguments to execute inside the container.

If no command is provided, the script will start an interactive `bash` shell inside the container.

### Options

-   `--runtime <runtime>`: Specify the container runtime (e.g., `podman`, `docker`). Defaults to `podman`.
-   `--add <type> <image>`: Add or update a container image in `~/.utils/images.yaml`.

### Basic Examples

```bash
# Check the installed Go version (uses podman by default)
run-in-container.sh golang go version

# Run a Python script using Docker
run-in-container.sh --runtime docker python my_script.py

# Get an interactive shell in a Node.js environment
run-in-container.sh node
```

### Managing Container Images

The script comes with a set of default images. You can override these defaults or add new images by creating a `images.yaml` file in your `~/.utils` directory. The `--add` flag provides a convenient way to do this.

#### Example: Adding a Bitcore Node Container

If you want to run a Bitcore node, you can add it to your `images.yaml` file like this:

```bash
run-in-container.sh --add bitcore bitcore/bitcore
```

This command will create the `~/.utils` directory and the `images.yaml` file if they don't exist, and add a new entry for `bitcore`. You can then use it like any other container type:

```bash
# Run the bitcore daemon
run-in-container.sh bitcore bitcored
```

Any images defined in `~/.utils/images.yaml` will take precedence over the script's built-in defaults.

## Advanced Usage

The script's power is unlocked via the `EXTRA_ARGS` environment variable, which allows you to pass any additional flags to the container runtime command.

### Example 1: Cached Rust Builds

To speed up builds, you can mount your local Cargo cache directories into the container.

```bash
# Set the environment variable to mount the cargo registry and git caches
export EXTRA_ARGS="-v $HOME/.cargo/registry:/usr/local/cargo/registry -v $HOME/.cargo/git:/usr/local/cargo/git"

# Run the build command from your project's root directory
run-in-container.sh rust cargo build --release
```

### Example 2: Building Container Images (Podman-in-Podman)

You can build a `Dockerfile` by giving the `podman` container access to your host's Podman service.

1.  **Find your Podman socket path:**
    ```bash
    podman info --format '{{.Host.RemoteSocket.Path}}'
    ```

2.  **Set `EXTRA_ARGS` to mount the socket:**
    ```bash
    # Replace the path with the output from the command above
    export PODMAN_SOCKET=$(podman info --format '{{.Host.RemoteSocket.Path}}')
    export EXTRA_ARGS="-v $PODMAN_SOCKET:/run/podman/podman.sock"
    ```

3.  **Run the build:**
    ```bash
    # Run from the directory containing your Dockerfile
    run-in-container.sh podman build -t my-awesome-app .
    ```

### Example 3: Using the Google Cloud CLI (`gcloud`)

To use `gcloud` commands, you need to provide authentication credentials to the container by mounting your local `gcloud` configuration directory.

1.  **Authenticate locally (if you haven't already):**
    ```bash
    gcloud auth application-default login
    ```

2.  **Set `EXTRA_ARGS` to mount the config directory:**
    ```bash
    # This makes your local gcloud credentials available inside the container
    export EXTRA_ARGS="-v $HOME/.config/gcloud:/root/.config/gcloud"
    ```

3.  **Run your `gcloud` command:**
    ```bash
    run-in-container.sh gcloud gcloud projects list
    ```

## Pro-Tip: Transparently Containerize Toolchains

To make the integration completely seamless, you can create aliases that "wrap" the primary command for each toolchain.

**Step 1: Create a dedicated alias file**

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

Add the following lines to the end of your `~/.bashrc` or `~/.zshrc` file.

```bash
# Load OCI aliases if the file exists
if [ -f ~/.oci_aliases ]; then
    . ~/.oci_aliases
fi
```

**Step 3: Reload your shell**

Open a new terminal window or run `source ~/.bashrc` (or `source ~/.zshrc`) to apply the changes. You can now use the commands like `go`, `cargo`, `gcloud`, etc., directly.
