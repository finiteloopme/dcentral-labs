# Use a standard Cloud Workstations base image
# FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest
FROM us-central1-docker.pkg.dev/cloud-workstations-images/predefined/base:latest

USER root

# Install prerequisites (Node.js, npm for Remix, curl, git for Foundry, and common utilities)
RUN apt-get update && \
    apt-get install -y \
    sudo \
    curl \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && apt-get install -y \
    nodejs \
    npm \
    # Add any other dependencies you might need
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN useradd -ms /bin/bash user
# Run as the 'user' since foundryup might have issues with root an_channel_user_agent_sandbox_lnx_remote_display_tests_test_output_0_sh_test_results_passed_txtd sometimes tries to write to /root
USER user
WORKDIR /home/user
RUN curl -L https://foundry.paradigm.xyz | bash && \
    /home/user/.foundry/bin/foundryup

# Add Foundry to PATH for all users
ENV PATH="/home/user/.foundry/bin:${PATH}"

# Install Remix IDE globally via npm
# Switch back to root to install global npm packages and set permissions
USER root
RUN npm install -g remix-ide

# Set up a simple script to launch Remix IDE on port 8080
# Cloud Workstations by default exposes port 80 for web applications.
# We will run Remix on 8080 and rely on the default launch URL or configure port forwarding.
# Alternatively, you can try to run it directly on port 80, but this might require additional configuration
# or running as root, which is generally not recommended for applications.
RUN echo '#!/bin/bash' > /usr/local/bin/start-remix.sh && \
    echo 'remix-ide' >> /usr/local/bin/start-remix.sh && \
    chmod +x /usr/local/bin/start-remix.sh

# Expose the port Remix IDE will run on
EXPOSE 8080

# Cloud Workstations will run /google/scripts/entrypoint.sh by default.
# We can add a custom startup script to launch Remix.
# Create a script that will be run at startup.
# This script will be executed after the default user is created.
RUN echo -e '\
#!/bin/bash
# Start Remix IDE as the 'user' in the background
# Ensure environment variables (like PATH for foundry) are available
# Redirect output to logs for debugging
sudo -u user bash -c "nohup /usr/local/bin/start-remix.sh > /home/user/remix-ide.log 2>&1 &"'\
>> /etc/workstation-startup.d/120_start-remix-ide.sh
# COPY --chown=user:user <<EOF /etc/workstation-startup.d/120_start-remix-ide.sh
# EOF

RUN chmod +x /etc/workstation-startup.d/120_start-remix-ide.sh

# Switch back to the default user for the workstation
USER user
WORKDIR /home/user

# Verify installations (optional, but good for debugging)
RUN echo "Verifying Foundry installation..." && \
    /home/user/.foundry/bin/forge --version && \
    /home/user/.foundry/bin/cast --version && \
    /home/user/.foundry/bin/anvil --version && \
    echo "Foundry verification complete." && \
    echo "To verify Remix, launch the workstation and access port 8080."