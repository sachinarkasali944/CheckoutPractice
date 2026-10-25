# Checkout interview questions with answers

## 1. How would you describe this design in 60 seconds?

A SwiftUI view renders an explicit checkout state owned by a main-actor ViewModel. An injected API protocol separates network behavior from presentation. Before submission, a key store persists one idempotency key per order. Repeated taps are blocked locally. Unknown results trigger bounded status polling. The backend owns payment truth and duplicate-charge prevention, while active-order persistence enables relaunch recovery.

## 2. Why is disabling Pay insufficient?

It only protects this UI instance. Retries, another device, app relaunch, and concurrent server requests still occur. The server needs atomic deduplication and a unique payment intent per order.

## 3. What does idempotency mean here?

Repeated submission of the same logical payment intent with the same key must return the existing payment instead of creating another financial effect. The server must validate the key's scope and request fingerprint.

## 4. When should the key be created and persisted?

Before sending the first payment request. Creating it after the response leaves a crash window where the server accepted payment but the client has no durable retry identity.

## 5. Why not generate a new UUID for every retry?

A new UUID tells the server it may be a new operation. After an unknown outcome, reuse the original key to identify the same intent.

## 6. Why is one key per order appropriate? When is it insufficient?

This exercise permits one payment intent per order. If the product supports retrying a confirmed decline, partial payments, split tenders, or multiple captures, model explicit payment attempts and their keys. A transport retry and a new business attempt are different operations.

## 7. A POST times out. What should the app display?

Confirmation pending. The backend may have accepted or completed payment before the response was lost. Query status and display success or decline only after authoritative confirmation.

## 8. Are all 4xx responses payment failures?

No. A rejected request is not a gateway decline, and 408/409/429 can require reconciliation. This project treats only contract-defined 400/401/403/422 POST responses as rejected. Real integrations need explicit semantics and often structured error codes.

## 9. Why does GET 404 sometimes enable retry?

If no acceptance has been observed, the start request may never have arrived. A same-key retry can recover. If acceptance was already observed, a later 404 may reflect stale reads or server inconsistency; enabling Pay would give misleading certainty. Backend atomicity must make retries safe in either case.

## 10. Is a 200 response sufficient to show success?

No. The body may contain PROCESSING. Decode the business status and verify order ID, amount, and currency before applying it.

## 11. Why use an enum instead of loading/success/error Booleans?

An enum makes presentation states mutually exclusive and makes switch statements enumerate the supported cases. Booleans allow contradictory combinations and unclear transitions.

## 12. Why is the ViewModel @MainActor?

It serializes UI state changes and coordinates tap guards on the main actor. Async network operations suspend without blocking the UI. Reentrancy across await means logical in-flight guards are still necessary.

## 13. Why make CheckoutAPI a protocol?

The ViewModel depends on capabilities rather than URLSession details. HTTP, demo, and test implementations can be substituted without changing checkout behavior. This also makes failure paths reproducible.

## 14. What does Sendable provide?

It expresses that a value or dependency can cross concurrency boundaries safely. It does not imply a network request is idempotent or make database operations atomic. The demo actor protects its own mutable in-process state.

## 15. Why use @StateObject in the view?

SwiftUI owns a stable ViewModel instance for the view's identity across redraws. The parent changes the checkout view's identity when the order changes, so a new order gets a new ViewModel.

## 16. Does cancelling the Task cancel payment?

No. It stops local observation and may cancel an in-flight URLSession operation. The server or gateway may already be processing payment. A true payment cancellation needs a separate backend command and race-handling policy.

## 17. Why bounded polling? Why not poll forever?

It limits battery, bandwidth, and server load. Exhaustion means unknown, not failure. Production systems can add backoff, jitter, Retry-After handling, push notifications, and server reconciliation without making the app responsible for final settlement.

## 18. How does app relaunch recovery work?

The app restores the active order and its API mode, recreates the API, then queries payment status. The durable key remains available if resubmission is allowed. In production, recover active orders from the authenticated backend as well, so reinstall or another device is supported.

## 19. Why use integer minor units for money?

Binary floating-point arithmetic can introduce rounding errors. Store money as integer units with a currency, or an appropriate decimal representation. Currency scale varies; this demo's division by 100 is specific to its INR scope.

## 20. Is UserDefaults appropriate for the key?

For this demo, yes: the key is an identifier, not a credential. Production decisions depend on durability and privacy requirements. Scope storage to the account, clear it on logout, and avoid using the key as authorization. Stronger storage is useful if lost writes are unacceptable.

## 21. What happens when two devices use different keys for the same order?

Key uniqueness alone cannot prevent two intents. The server must enforce a unique order payment intent and return or conflict with the existing payment. Both clients then reconcile its status.

## 22. Can a database transaction include the gateway charge?

Not as one ordinary local transaction. Persist intent, use a stable provider idempotency key, and reconcile unresolved outcomes. An outbox helps dispatch reliably after commit; duplicate consumers still need protection.

## 23. What if the server crashes after charging but before saving success?

It must recover via the provider's key/reference lookup, a verified webhook, or a reconciliation job. Retrying blindly with a new provider key risks a duplicate charge.

## 24. How do you process duplicate or out-of-order webhooks?

Verify authenticity, deduplicate event identifiers, and enforce valid transitions transactionally. A late PROCESSING event must not overwrite SUCCEEDED. Refunds and disputes require separate explicit states or records.

## 25. What do the tests prove, and what do they not prove?

They verify client orchestration, key reuse, cancellation semantics, and the simulated server's stable payment identity. They cannot prove a real backend's database atomicity, gateway deduplication, webhook authenticity, or distributed recovery. Those need integration and concurrency tests against actual components.

## 26. Which SOLID ideas are useful here?

Each type has a focused responsibility. The ViewModel depends on a small API abstraction. New API implementations can be added without changing presentation orchestration. Keep these practical; adding a protocol for every value object does not improve the design.

## 27. Is this the GoF State pattern?

It is an explicit enum-based state machine. It does not use a separate class implementing a State interface for every state. That heavier pattern is only useful when state-specific behavior justifies it.

## 28. What would you improve first for production?

Confirm the server's atomic one-intent-per-order contract, add authenticated active-order recovery, and define gateway reconciliation. Then improve account-scoped persistence, structured errors, observability, backoff, and accessibility. The most polished UI cannot compensate for unsafe backend money transitions.
