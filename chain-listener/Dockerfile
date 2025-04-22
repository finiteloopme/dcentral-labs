# syntax=docker/dockerfile:1

FROM golang:1.24.2 AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY cmd/ ./cmd/
COPY config/ ./config/
COPY pkg/ ./pkg/
# COPY metadata.json .
COPY config.toml .
COPY Makefile .
RUN make build-prod

FROM apache/beam_go_sdk:2.64.0
COPY --from=build /app/bin/chain-log-listener ./chain-log-listener