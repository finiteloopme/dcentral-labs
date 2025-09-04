# Using multi-stage builds to create a small, secure image.

# Stage 1: Build the application
#
# We use the official Rust image as our builder.
FROM rust:1.85 AS builder

# Create a new empty shell project in the working directory.
WORKDIR /usr/src/app
# Copy the local code to the container.
COPY . .

# Build the application for release.
# This creates a statically linked binary in the `target/release` directory.
RUN cargo build --release

# Stage 2: Create the final, small image
#
# We use a small Debian image as our final base image.
FROM debian:buster-slim

# Copy the built binary from the builder stage to the final image.
COPY --from=builder /usr/src/app/target/release/backend /usr/local/bin/backend

# Set the binary as the entrypoint for the container.
# This means that when the container starts, it will run our application.
CMD ["backend"]
