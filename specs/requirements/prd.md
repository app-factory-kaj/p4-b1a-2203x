# Greeter Service — PRD

## Problem Statement

Teams building services and demos on this platform repeatedly need a minimal, dependable "hello world"-style endpoint to verify wiring, pipelines, and conventions before investing in a real feature. Without a shared, trivial reference service, each team reinvents this scaffold on its own, costing time and producing inconsistent conventions.

## Solution

A tiny greeter service exposing a single endpoint that returns a hello message, optionally personalized with a caller-supplied name. It exists to be simple, reliable, and to follow this organization's standard repo and service conventions, so it can double as a reference implementation for other services. This project also serves as a Phase 4 checkpoint probe.

## Actors

- **Caller** — another internal service or client application that invokes the greeter endpoint to obtain a hello message. *assumed*

## User Stories

1. As a Caller, I want to request a greeting, so that I receive a friendly hello message confirming the service is reachable and working.
2. As a Caller, I want to optionally supply a name, so that the greeting returned is personalized to me.

## Product Decisions

- Callers are other internal services/apps, not end users via a UI. *assumed*
- The greeting is personalized: when a name is supplied the response is "Hello, &lt;name&gt;!"; when omitted, the service returns a generic greeting (e.g. "Hello, World!"). *assumed*
- The endpoint requires no authentication — it is an open endpoint, fitting for a tiny utility/reference service with no sensitive data. *assumed*

## Out of Scope

- No persistence or storage of any kind — the service is stateless.
- No user-facing web interface.
- No rate limiting, analytics, or multi-language greetings.

## Open Questions

None at this time.

## Further Notes

None.