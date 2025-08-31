# Using multi-stage builds to create a small, secure image.

# Stage 1: Build the application
FROM rust:1.76 AS builder

WORKDIR /usr/src/app
COPY . .

RUN cargo build --release

# Stage 2: Create the final, small image
FROM debian:buster-slim

COPY --from=builder /usr/src/app/target/release/proof-service /usr/local/bin/proof-service

CMD ["proof-service"]
