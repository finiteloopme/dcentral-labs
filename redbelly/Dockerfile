# FROM node:20 as builder_node
# WORKDIR /app
# COPY package*.json ./
# RUN npm install
# COPY . .
# RUN npm run build

FROM python:3.10 AS builder_python
WORKDIR /app
COPY ./ai-manager/app ./

FROM golang:1.24 AS builder_go
WORKDIR /app
COPY ./evm-mcp/go.mod ./evm-mcp/go.sum ./
RUN go mod download
COPY ./evm-mcp .
RUN make clean
RUN go install github.com/ethereum/go-ethereum/cmd/abigen@latest
RUN make abi2go
RUN make build

# FROM ubuntu:latest
# RUN apt-get update && apt-get install -y python3.10 python3.10-pip nodejs npm python3.10-venv
FROM python:3.10
RUN apt-get update && apt-get install -y nodejs npm git
# COPY --from=builder_node /app/dist /app/dist
WORKDIR /app
COPY --from=builder_python /app /app
COPY --from=builder_go /app/bin/evm-mcp-rwa /app/mcp
RUN chmod +x /app/mcp
# RUN python3 -m venv .venv
# RUN . .venv/bin/activate
# RUN ./.venv/bin/pip install google-adk
# RUN rm -fr .venv/lib/python3.10/site-packages/google/adk/cli/browser
# RUN mkdir -p .venv/lib/python3.10/site-packages/google/adk/cli/browser
# COPY ./ai-manager/adk-web/dist/agent_framework_web/browser .venv/lib/python3.10/site-packages/google/adk/cli/browser
RUN pip install git+https://github.com/finiteloopme/adk-python.git 
RUN chmod +x setup.sh
EXPOSE 8000

CMD ["./setup.sh"]