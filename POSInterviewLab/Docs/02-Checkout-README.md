# Lab 1 — Checkout and reconciliation

## Business flow

Merchant builds a cart → app snapshots the amount → payment attempt gets a stable ID → provider processes → app displays a receipt only after confirmation. A response loss introduces **unknown**, not declined.

In real payments, authorization reserves funds; capture submits the authorized transaction for collection; settlement moves funds through the financial network. The demo collapses these stages into `approved`; it does not model banking settlement.

## Read and trace

1. `canPay` requires no active operation, no unresolved attempt and a ready payment method.
2. `pay()` sets `busy` before its first await. MainActor serializes access but permits another task to enter while suspended, so the guard still matters.
3. The pending UUID is saved before invoking the gateway.
4. DemoGateway atomically commits an approval, then intentionally throws a timeout for the failure scenario.
5. The app retains the UUID, blocks a new sale and offers status lookup.
6. A relaunch loads both the pending UUID and fake server ledger.
7. Lookup returns the recorded result. Unknown is resolved; a receipt or decline appears.

The mock actor contains no suspension between checking the key and committing, so concurrent calls on this one actor serialize. A production server must enforce uniqueness and request-payload consistency in a database transaction across processes. Client-side `isLoading` alone cannot prevent duplicate charges.

## Money and identity

INR uses two minor-unit decimal places: 15000 means INR 150.00. Double is used only to display the amount. Persist currency with every order in a real system; not all currencies have two decimal places. Bound quantities and use overflow checks for general-purpose price arithmetic.

Reuse a key only for the same logical request and payload. A definitive decline allows a new attempt with a new key. A timeout does not establish a decline. Store the order ID, attempt ID, method, amount, currency and reconciliation metadata together in production.

## Recovery nuance

The fake lookup is strongly consistent and authoritative. A real `404` may mean replication lag or an in-flight request. Never clear a real pending payment merely because a single lookup found nothing. Follow the provider contract, poll with bounded backoff, consume backend webhook outcomes, and offer a support reference. Cancelling the Swift task cannot undo a committed payment.

## Refund nuance

The demo supports full refund only and uses the original payment ID to make repetition return the same state. Real partial refunds need separate refund keys, authorized merchant permissions, a cumulative refundable balance invariant and their own unknown-outcome recovery. A receipt is not a fiscal/tax-compliant invoice.

## Practice

- Recreate `pay()` and `recover()` without looking.
- Add an injected fake that returns pending twice before approved.
- Replace UserDefaults with an atomic client journal and surface disk failures.
- Add a test proving a second Pay tap never invokes the gateway while the first is suspended.
- Add persisted receipt history and inventory decrement after confirmed success, exactly once per order.
