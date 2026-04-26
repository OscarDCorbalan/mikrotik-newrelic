---
description: "Project overview including tech stack, architecture patterns, and coding conventions for the repository."
alwaysApply: true
---

# Project Overview

## Summary

This project provides a MikroTik router script that sends system metrics to New Relic. It creates a New Relic entity for each MikroTik router where the script runs in, with metrics and tags for monitoring CPU, memory, network throughput, and other router statistics.

## Tech Stack

- **MikroTik RouterOS**: Runs on MikroTik routers
- **New Relic**: Metrics are sent to New Relic's Metric API for monitoring and visualization

## Architecture & Coding Standards

- Uses MikroTik's scripting language (RouterOS Scripting)
- Designed to be run as a scheduled task in MikroTik's scheduler
- Metrics are structured in JSON format compliant with New Relic's Metric API
- Uses MikroTik's `/tool fetch` command to send HTTPS requests
- Implements helper functions for JSON serialization and timestamp generation
- Metrics are tagged with router attributes for identification and filtering
- Configuration is done through local variables at the top of the script
- Error handling is minimal but includes debugging instructions in the README
- Router interface metrics are dynamically collected for all interfaces

## Key File Locations

- `src/newrelic-metrics.rsc`: Main script that collects metrics and sends to New Relic
- `README.md`: Documentation with setup instructions and troubleshooting

## Additional Notes

- Requires a New Relic Insert API key (instructions in README)
- Metrics are collected every 15 seconds by default (configurable)
- Supports both US and EU New Relic regions (configurable)
