# Ten sessions — 60 to 90 minutes each

| Session | Work | Interview evidence |
| --- | --- | --- |
| 1 | Run the app, approve/decline payments, draw boundaries | Explain POS versus customer checkout |
| 2 | Rewrite Money/Payment/Gateway models | Explain minor units and attempt identity |
| 3 | Trace timeout-after-approval and relaunch recovery | Explain why timeout is unknown |
| 4 | Read and run the concurrent idempotency tests | Explain client guard versus backend invariants |
| 5 | Rebuild ReaderMachine; add timeout and stale callback tests | Bridge Bosch BLE to POS |
| 6 | Trace Tap preparation, token expiry and provider boundary | Explain entitlement, PSP and configuration |
| 7 | Design hosted Key In and account switching | Explain card data and merchant isolation |
| 8 | Extend to a refund journal and pending refunds | Explain retry safety and refundable balance |
| 9 | Practise the incident runbook and rollout design | Explain senior ownership and merchant impact |
| 10 | Build checkout from scratch in 45 minutes; answer Q&A aloud | Present tradeoffs and limitations confidently |

## Start with session 1

Run `POSInterviewLab.xcodeproj`. Complete the response-loss walkthrough in the root README. Then answer without looking: “What information survives an app restart, and why is it unsafe to issue a new charge immediately?”

## Follow-on projects after the core lab

1. **Reader Reliability Lab**: vendor SDK adapter or a BLE peripheral you own, operation IDs, stale callback rejection and hardware integration tests. Acceptance: a disconnect during payment never changes financial status to declined.
2. **Merchant Operations Lab**: product library, durable cart/order journal, inventory events, receipt history and partial refund ledger. Acceptance: applying the same payment success event twice changes stock once.
3. **Provider Sandbox Lab**: choose a supported PSP, complete approved setup and replace demo preparation/processing with documented sandbox flows. Acceptance: no server secrets in the app, no card data in app-owned logs, documented unknown-result recovery.

These are future exercises, not additional completed applications in this commit.
