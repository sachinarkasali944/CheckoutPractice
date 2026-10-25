# API contract and server responsibilities

This is the contract expected by the supplied Swift models. JSON uses the exact camel-case property names, including `orderID`. No Go source or gateway implementation was provided.

## Endpoints

| Method | Path | Request | Successful response |
| --- | --- | --- | --- |
| POST | `/orders` | No body in this exercise | Order JSON, normally 201 |
| POST | `/orders/{orderID}/payment` | `Idempotency-Key` header; no body | Payment JSON, 200/201/202 |
| GET | `/orders/{orderID}/payment` | No body | Payment JSON, 200 |

Every successful response must include decodable JSON, including a 202. A 204 cannot satisfy the current client model.

Order example:

```json
{"id":"order-1","amountMinor":49900,"currency":"INR","status":"CREATED"}
```

Payment example:

```json
{"id":"payment-1","orderID":"order-1","amountMinor":49900,"currency":"INR","status":"PROCESSING"}
```

Order statuses: `CREATED`, `PAYMENT_PENDING`, `PAID`, `PAYMENT_FAILED`.
Payment statuses: `PROCESSING`, `SUCCEEDED`, `FAILED`.

The server computes amount/currency from its order. The client cannot declare a payment successful. The demo's create-order endpoint substitutes a fixed cart worth ₹499.00.

## Error semantics used by the client

- 400/401/403/422 on POST: request rejected before payment acceptance under this demo contract. Show rejected, not declined. Still allow a later status check.
- 408/409/429, 5xx, transport timeout, or decoding error on POST: query status because acceptance may have happened.
- 404 on GET: no payment found. Before known acceptance, allow same-key resubmission. After known acceptance, continue bounded observation.
- Other GET failures: continue observation until the budget expires, then show unknown.
- A backend payment with `FAILED`: confirmed payment decline, distinct from a rejected HTTP request.

Auth recovery and conflict-specific error bodies are omitted. Confirm these semantics before connecting a different server. A network failure while reading a response can hide any status code.

## Minimum server design for discussion

1. Authenticate the caller and authorize ownership of the order.
2. Validate the order is payable; use its stored amount and currency.
3. Atomically claim the idempotency key, scoped by account and operation; store a request fingerprint.
4. Enforce a unique payment intent per order for this exercise. Concurrent requests using different keys must not produce independent charges.
5. Same key + same request returns the existing payment/result. Same key + different request is a conflict.
6. Persist a payment intent before contacting a gateway. Propagate a stable gateway key where supported.
7. Record authoritative terminal events from gateway confirmation, verified webhooks, or reconciliation jobs. Duplicate and out-of-order events must not regress terminal status.
8. Expose a consistent status lookup and reconcile crashes or lost gateway responses independently of the app.

Suggested data:

```text
orders(id PK, account_id, amount_minor, currency, status)
payments(id PK, order_id UNIQUE FK, gateway_reference, status)
idempotency(account_id, operation, key, request_hash, payment_id,
            UNIQUE(account_id, operation, key))
```

A database transaction cannot atomically include a third-party gateway call. Use durable intent plus provider idempotency and reconciliation. An outbox can reliably publish work after commit, but consumers still need idempotency.

This provides an effectively-once business effect under the stated contracts; HTTP delivery itself is not exactly once. Define key retention, gateway retention, and order uniqueness together. Keep order uniqueness beyond expiration of a transport deduplication key.

## Demo limitations

The local actor mimics key conflicts, stable payment identity, response loss, and terminal status after elapsed time. UserDefaults is a learning shortcut, not a transactional database. Multiple app processes do not share an actor lock. The demo does not implement server authentication, webhooks, rate limits, gateway calls, or cross-process atomicity.
