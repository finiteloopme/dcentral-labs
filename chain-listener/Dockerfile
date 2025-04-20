FROM golang:latest AS build
WORKDIR /
COPY . .
RUN make build-prod

FROM apache/beam_go_sdk:2.64.0
COPY --from=build bin/chain-log-listener ./chain-log-listener