# geth-24-monitor

**Goal:** implement basic node health checks (block freshness/lag) and discuss alerting patterns.

## Big Picture

Monitoring a node involves tracking head freshness, RPC latency, and error rates. Simple checks catch stale nodes early; production systems export metrics to Prometheus/Grafana and alert on thresholds.

## Learning Objectives
- Fetch latest header and estimate lag.
- Classify status (OK/STALE) based on block age.
- Consider additional metrics (latency, error counts) for production.

## Prerequisites
- Module 20 (node info) and 21 (sync) helpful.

## Real-World Analogy
- Vital signs monitor: heart rate (block cadence), temperature (latency), alarms on abnormal values.

## Steps
1. Parse RPC, max lag.
2. Fetch latest header.
3. Compute rough lag (timestamp vs wall clock) and print status.

## Fun Facts & Comparisons
- Block time varies by network; tune thresholds accordingly.
- Public RPCs can appear stale if rate-limited; own node gives clearer signals.
- Prometheus exporter patterns: track head age, RPC latency, failure counts.

## Related Solidity-edu Modules
- None directly; this supports reliable dev/test infra.

## Files
- Starter: `cmd/geth-24-monitor/main.go`
- Solution: `cmd/geth-24-monitor_solution/main.go`
