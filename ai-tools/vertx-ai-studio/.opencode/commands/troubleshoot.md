---
description: Troubleshoot issues using logs, Prometheus metrics, and system diagnostics
agent: devops
---

$ARGUMENTS

This is a unified troubleshooting workflow covering logs, metrics, and system health.

**Step 1: Determine scope from arguments**

If $ARGUMENTS specifies a file path (contains `/` or ends in `.log`):
- Use `read_logs` with the file path as target (source auto-detection will resolve to "file")
- Then use `extract_errors` on the same target to find issues
- Skip discovery — go straight to analysis

If $ARGUMENTS specifies a container name, build ID, or systemd unit:
- Use `read_logs` with the target (source auto-detection will resolve the type)
- Then use `extract_errors` on the same target
- Skip discovery — go straight to analysis

If $ARGUMENTS mentions "compare" or "diff" with two targets:
- Use `compare_logs` with the two targets as `good` and `bad`
- Analyse the differences and identify likely root cause

If $ARGUMENTS mentions "metrics", "prometheus", "cpu", "memory", "oom", or "latency":
- Use `discover_prometheus` to find the Prometheus endpoint
- Use `query_metrics` with relevant pre-built queries:
  - CPU: `rate(container_cpu_usage_seconds_total[5m])`
  - Memory: `container_memory_usage_bytes / container_spec_memory_limit_bytes`
  - OOM/restarts: `increase(kube_pod_container_status_restarts_total[1h])`
  - Latency: `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))`
  - Error rate: `rate(http_requests_total{code=~"5.."}[5m]) / rate(http_requests_total[5m])`
- If a specific PromQL query is provided, run it directly

If $ARGUMENTS mentions "targets" or "scrape":
- Use `check_targets` to show Prometheus scrape target health

If $ARGUMENTS mentions "ports", "dns", "connectivity", or "network":
- Use the appropriate system tool: `check_ports`, `check_dns`, or `check_connectivity`

If $ARGUMENTS mentions "disk" or "storage":
- Use `disk_usage` to check disk space

If $ARGUMENTS mentions "processes" or "top":
- Use `process_list` to show resource-heavy processes

If $ARGUMENTS is empty or says "everything" / "what's wrong" / "diagnose":
- Run the full diagnostic suite:
  1. `discover_sources` to find all available log sources
  2. For each discovered source, run `extract_errors` to find issues
  3. `discover_prometheus` to check for metrics endpoint
  4. If Prometheus is available, run key health queries:
     - `up` (target availability)
     - `rate(container_cpu_usage_seconds_total[5m])` (CPU)
     - `container_memory_usage_bytes` (memory)
  5. `system_info` for system overview
  6. `container_health` for container status
- Use `since: "1h"` as default time window

**Step 2: Analyse and report**

Load the `troubleshooting` skill for domain-specific diagnostic knowledge.

For each source with findings, present a structured diagnostic summary:

1. **Source** — what was checked (file path, container name, build ID, metric)
2. **Severity** — count of critical/error/warning messages found
3. **Key findings** — the most significant errors or anomalous metrics with context
4. **Likely cause** — your assessment based on the error patterns, metric values,
   and the troubleshooting skill's decision trees
5. **Suggested action** — what to try next to resolve the issue

Number each finding for drill-down reference.

**Step 3: Offer next steps**

After presenting the summary, offer:
- "Want me to dig deeper into finding #N?"
- "Should I run a custom PromQL query?"
- "Want me to check metrics for the time window around this error?"
- "Should I compare against a previous successful run?"
- "Want me to create a GitHub issue for this error?"
