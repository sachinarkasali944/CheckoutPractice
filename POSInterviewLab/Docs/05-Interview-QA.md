# Interview answers to practise aloud

## 1. How does your BLE experience transfer to POS?

“I owned Bosch tool connectivity and a device protocol abstraction. The transport concerns transfer: discovery, handshake, retries and stale callbacks. Payments introduce another dimension: transport success is not payment success, so I separate reader readiness from financial state and reconcile ambiguous outcomes.”

## 2. Merchant tapped Pay twice. What prevents duplicate charges?

“An immediate UI guard prevents duplicate user actions. A stable attempt key and server-side idempotency protect across retries, app restarts and concurrent clients. The server validates that a reused key has the same merchant, amount, currency and payload.”

## 3. The card was charged, but the app timed out. What now?

“Persist the attempt before sending. Mark the UI outcome unknown, block another charge for that sale, and query the authoritative backend using the original identity. Never infer decline from a timeout. Backend webhooks and a reconciliation worker handle late results.”

## 4. Why does MainActor not solve duplicate submissions by itself?

“Actor isolation prevents simultaneous access to isolated state. At await, another task may enter. I set the busy state before awaiting and retain the unresolved attempt until the operation is reconciled.”

## 5. Is the fake server actor production idempotency?

“No. It serializes one process and writes an atomic local file. Production idempotency needs transactional uniqueness across all server instances, consistent payload comparison and a defined retention policy.”

## 6. Reader disconnects after a tap. Retry the charge?

“Reconnect the hardware separately. Keep the payment unresolved and reconcile it first. A BLE disconnect tells me about the link, not whether the provider authorized the transaction.”

## 7. What is required for Tap to Pay?

“A supported PSP, Apple entitlement and supported device/account/region setup. The app prepares the reader using provider configuration and credentials, then follows the certified read and processing flow. My lab simulates those boundaries; it does not process cards.”

## 8. What belongs in analytics?

“Sanitized lifecycle events, durations, error categories and approved correlation identifiers. Exclude PAN, CVV, PIN, authorization headers, access tokens and raw SDK payloads. Apply data minimization and retention rules.”

## 9. Can we accept payment offline?

“Only if the provider explicitly supports the specific offline flow and the business accepts its limits and risk. I would not queue arbitrary charge requests and assume approval. An offline cart and an approved offline payment are different capabilities.”

## 10. How do you test without payment hardware?

“Inject gateway and reader abstractions. Test declines, timeout after server commit, pending status, duplicates, session expiry and stale callbacks deterministically. Add vendor sandbox and physical-device tests for the real transport and certified flow.”

## 11. What is your refund strategy?

“Authorize the merchant operation, use an independent refund idempotency key, enforce refundable balance transactionally and reconcile unknown refund results. My demo only models a full, immediate, repeatable refund.”

## 12. How would you release a payment change?

“Review financial invariants and compatibility, test the provider sandbox and supported hardware, then release to internal and pilot cohorts. Monitor approval rates, unknown outcomes, duplicate signals, reader failures and crashes. Define owners and stop criteria before rollout.”

## 13. How would you take over ownership from Sweden?

“I would inventory modules, provider contracts, signing capabilities, release automation, dashboards and open incidents. Shadow a release, pair on one production issue, document failure modes and decision owners, then run a reverse-shadow release with explicit acceptance criteria.”

## 14. What are the main limitations of this project?

“Simulated provider and reader, no real ProximityReader or Key In, simplified server persistence, no full order journal, no taxes/inventory or partial refunds. It demonstrates the financial-state boundary and gives me testable seams for real integration.”
