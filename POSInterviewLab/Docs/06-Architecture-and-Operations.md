# Architecture decision record and operations

## ADR 001 — Isolate the financial boundary

Status: accepted for learning.

Context: hardware connectivity and backend financial outcome can fail independently. Combining both in `isConnected` risks false success or duplicate charging.

Decision: LabModel owns main actor presentation state. PaymentGateway defines financial operations. DemoGateway owns an actor-isolated durable fake ledger. ReaderMachine owns explicit transport lifecycle states. Injecting a production gateway is a future extension; LabModel currently constructs the fake gateway in its composition root initializer.

Consequence: UI exercises run with no hardware or credentials. There is no claim of PCI certification, provider integration, or multi-process safety. A real app should split composition from the view model and model CheckoutState as an enum with associated values to make invalid combinations impossible.

## Financial invariants

- Pending financial identity survives view replacement and relaunch.
- New charge is blocked while the prior attempt is unresolved.
- Same key plus changed amount/method fails.
- Receipt is shown only for a known result.
- Refund cannot apply to a declined transaction.
- Cancellation does not prove reversal of a server operation.

## Runbook — Unknown payment spike

Trigger: unknown outcomes rise versus the normal baseline, especially after a rollout.

1. Appoint an incident owner; record start time, app version, PSP/reader versions and affected merchant cohort.
2. Check backend/provider health and correlate sanitized attempt IDs. Never collect full card details in a support ticket.
3. Keep unresolved sales pending. Tell support to check provider status before requesting another payment.
4. Pause rollout or disable the affected new payment route with a reviewed kill switch. Keep status lookup available.
5. Reconcile outstanding attempts; investigate duplicate financial records through the provider/backend.
6. Verify recovery by cohort, publish the incident timeline and record prevention actions.

Demo events are an in-memory teaching aid. Production observability needs structured telemetry, correlation, latency, retention, alert thresholds and privacy review. Do not log tokens or raw reader data.

## Release checklist exercise

- Explain backward compatibility of persisted attempts before changing their schema.
- Agree on pending-payment recovery during logout/account migration.
- Test VoiceOver, Dynamic Type, localization and iPad layout on devices.
- Use pilot merchants and staged rollout with pre-agreed stop criteria.
- Prefer server-side feature disablement for immediate mitigation; App Store rollback is not instantaneous.
- Rehearse support escalation and provider outage handling.
