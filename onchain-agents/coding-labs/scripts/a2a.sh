#!/usr/bin/env bash
# A2A operations: health, agent-card, send
# Usage: AGENT=midnight ./scripts/a2a.sh send "your message"
#        Default agent: somnia (controlled by AGENT env var)

source "$(dirname "$0")/common.sh"

# Get agent URL based on AGENT env var (default: somnia)
readonly CURRENT_AGENT="${AGENT:-somnia}"
readonly AGENT_URL="$(get_agent_url "$CURRENT_AGENT")"

log_info "Targeting agent: ${CURRENT_AGENT} at ${AGENT_URL}"

cmd_health() {
  log_header "Health Check"
  
  local response
  if response=$(curl -s "${AGENT_URL}/health" 2>/dev/null); then
    log_success "Agent is healthy"
    echo "$response" | jq . 2>/dev/null || echo "$response"
  else
    log_error "Agent is not responding at ${AGENT_URL}"
    exit 1
  fi
}

cmd_agent_card() {
  log_header "Agent Card"
  
  local response
  if response=$(curl -s "${AGENT_URL}/.well-known/agent-card.json" 2>/dev/null); then
    echo "$response" | jq . 2>/dev/null || echo "$response"
  else
    log_error "Failed to fetch agent card from ${AGENT_URL}"
    exit 1
  fi
}

cmd_send() {
  local message="$1"
  
  if [ -z "$message" ]; then
    log_error "Message is required"
    echo "Usage: a2a.sh send \"Your message here\""
    exit 1
  fi
  
  log_header "Sending message to agent"
  log_info "Message: $message"
  echo ""
  
  # Generate UUIDs for the request
  local message_id
  local task_id
  message_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
  task_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
  
  # Prepare JSON-RPC request
  local payload
  payload=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "id": "${task_id}",
  "method": "message/send",
  "params": {
    "message": {
      "messageId": "${message_id}",
      "role": "user",
      "kind": "message",
      "parts": [
        {
          "kind": "text",
          "text": "${message}"
        }
      ]
    }
  }
}
EOF
)
  
  log_info "Request:"
  echo "$payload" | jq . 2>/dev/null || echo "$payload"
  echo ""
  
  log_info "Response:"
  local response
  response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${AGENT_URL}/")
  
  echo "$response" | jq . 2>/dev/null || echo "$response"
}

cmd_send_stream() {
  local message="$1"
  
  if [ -z "$message" ]; then
    log_error "Message is required"
    echo "Usage: a2a.sh send-stream \"Your message here\""
    exit 1
  fi
  
  log_header "Sending message to agent (streaming)"
  log_info "Message: $message"
  echo ""
  
  # Generate UUIDs for the request
  local message_id
  local task_id
  message_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
  task_id=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
  
  # Prepare JSON-RPC request for streaming
  local payload
  payload=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "id": "${task_id}",
  "method": "message/stream",
  "params": {
    "message": {
      "messageId": "${message_id}",
      "role": "user",
      "kind": "message",
      "parts": [
        {
          "kind": "text",
          "text": "${message}"
        }
      ]
    }
  }
}
EOF
)
  
  log_info "Streaming response:"
  curl -s -N -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: text/event-stream" \
    -d "$payload" \
    "${AGENT_URL}/"
}

cmd_skills() {
  log_header "Agent Skills"
  
  local response
  if response=$(curl -s "${AGENT_URL}/.well-known/agent-card.json" 2>/dev/null); then
    echo "$response" | jq '.skills[] | {id, name, description}' 2>/dev/null || {
      log_error "Failed to parse skills"
      exit 1
    }
  else
    log_error "Failed to fetch agent card from ${AGENT_URL}"
    exit 1
  fi
}

# Main
case "${1:-}" in
  health)
    cmd_health
    ;;
  agent-card)
    cmd_agent_card
    ;;
  send)
    cmd_send "${2:-}"
    ;;
  send-stream)
    cmd_send_stream "${2:-}"
    ;;
  skills)
    cmd_skills
    ;;
  *)
    show_usage "a2a.sh" "
  health        Check agent health
  agent-card    Fetch and display agent card
  skills        List agent skills
  send \"msg\"    Send a message to the agent
  send-stream \"msg\"  Send a message with streaming response

Environment Variables:
  AGENT         Target agent (default: somnia, options: somnia, midnight)

Examples:
  ./scripts/a2a.sh health                          # Check somnia agent
  AGENT=midnight ./scripts/a2a.sh health           # Check midnight agent
  AGENT=midnight ./scripts/a2a.sh send \"Generate a counter contract\""
    exit 1
    ;;
esac
