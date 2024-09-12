FROM rust:1.81.0-slim-bookworm AS builder
RUN rustup target add x86_64-unknown-linux-musl

WORKDIR /app
COPY Cargo.toml /app
COPY Cargo.lock /app
RUN mkdir -p /app/src

# dummy build to cache dependencies
RUN echo "fn main() {}" > /app/src/main.rs
RUN cargo build --release --target=x86_64-unknown-linux-musl

COPY src /app/src
COPY README.md /app
# RUN cargo clean
RUN cargo build --release --target=x86_64-unknown-linux-musl

FROM debian:bookworm-20240904
RUN apt-get update
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/net-latency .
ENTRYPOINT [ "./net-latency" ]