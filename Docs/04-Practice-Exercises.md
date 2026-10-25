# Practice exercises

## A 45-minute LLD interview rehearsal

1. **0–5 minutes:** clarify whether an order can have multiple payment attempts, who owns the amount, and how pending payments resolve.
2. **5–12 minutes:** identify Order, Payment, CheckoutAPI, key storage, ViewModel, and View. State the no-duplicate-effect and backend-truth invariants.
3. **12–22 minutes:** draw the state machine and timeout sequence from memory.
4. **22–32 minutes:** implement the Pay guard, durable key lookup, and status application.
5. **32–40 minutes:** discuss concurrent devices, server crashes, webhooks, and atomic intent creation.
6. **40–45 minutes:** outline tests and explain the exercise's deliberate limits.

## Hands-on drills

| Drill | Completion check |
| --- | --- |
| Rapidly tap Pay | One API submission, one key |
| Use lost-response scenario | Eventual success without another payment intent |
| Use pending scenario | Unknown after bounded polling; manual check starts another window |
| Quit during confirmation and reopen | Existing order is restored and status is queried |
| Return to the screen after backgrounding | Status refresh resumes |
| Run unit tests | All twelve pass |

## Extensions, in order

1. **Replace fixed polling with backoff and jitter.** Inject a sleeper/clock so tests do not wait. Assert the maximum number of calls and cancellation behavior.
2. **Model retry after a confirmed decline.** Introduce PaymentAttempt with an explicit attempt identifier. Document when a new key is valid and how duplicate attempt creation is prevented.
3. **Handle authentication expiry.** Preserve the active order and key through sign-in; query status after authorization returns. Never silently switch the saved order to another account.
4. **Support currency scale.** Remove the hard-coded two-decimal display assumption. Cover INR, JPY, and a three-decimal currency with explicit minor-unit metadata.
5. **Inject HTTP transport tests.** Use a URLProtocol stub and an ephemeral URLSession to assert path, method, Idempotency-Key, decoding, 202-with-body behavior, and malformed data handling.
6. **Add a real backend.** Start with a unique order-payment constraint and atomic key claim. Stress concurrent requests with both identical and different keys; verify one provider operation.
7. **Persist observation history.** Retain known acceptance across ViewModel recreation. Define how to recover when local history is lost and the backend status endpoint temporarily returns stale 404.

## Self-review prompts

- Can a transport failure ever turn into a displayed decline without backend confirmation?
- Can a retry change the key for the same logical payment?
- Can two independent clients bypass every local guard? What server rule protects them?
- Can terminal status regress after a delayed response?
- Does cancellation describe local observation or an actual business command?
- What state survives a crash, logout, reinstall, or another device?
- Which claims are verified by tests, and which depend on backend guarantees?
