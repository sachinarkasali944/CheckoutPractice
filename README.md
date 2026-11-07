# Checkout LLD Practice

A small SwiftUI app based on your pasted `Checkout.swift`. Practice one use case: **submit a payment once, and recover safely when its outcome is unknown**.

## Run in Xcode

1. Open `CheckoutPractice.xcodeproj`.
2. Select the **CheckoutPractice** scheme.
3. Choose an iPhone Simulator (iOS 16+) or **My Mac** (macOS 13+).
4. Press **⌘R**, choose a demo scenario, create an order, then tap Pay.

No external packages, backend, signing team, or payment account are needed for the default demo. Physical iPhone deployment requires your own signing team. The app supports macOS so you can practice without installing an iOS runtime.

## Try these scenarios

| Scenario | What to observe |
| --- | --- |
| Payment succeeds | Submitting → confirming → success, after about four seconds |
| Response lost, payment succeeds | The simulated server accepts payment but the POST times out; status lookup still finds success |
| Payment declined | Only the backend's `FAILED` payment produces the declined screen |
| Confirmation stays pending | Ten lookups finish with unknown; Check status starts another observation window |
| Request rejected (422) | Rejected screen, distinct from a payment decline |

Tap Pay repeatedly; only one submission should start. Close and reopen the app during confirmation: the active order, key, and demo server record survive. Returning to an active scene also checks status. Leaving an order starts a separate exercise; it does not cancel its payment.

## Project structure

Feature folders keep related MVVM types together. The folders in Xcode mirror the filesystem.

```text
CheckoutPractice/
├── App/
│   └── CheckoutPracticeApp.swift
├── Features/
│   ├── Checkout/
│   │   ├── Models/         # Order, Payment and their backend statuses
│   │   ├── Persistence/    # Durable payment key storage
│   │   ├── Services/       # API contract, HTTP adapter and demo backend
│   │   ├── ViewModels/     # Checkout presentation state and orchestration
│   │   └── Views/          # Checkout UI
│   └── Practice/
│       └── Views/          # Demo setup and active-order restoration
└── Resources/
    └── Info.plist
CheckoutPracticeTests/
└── Features/Checkout/      # Checkout unit tests
Docs/                      # LLD notes, API contract, Q&A and exercises
```

Read `Models`, `Services/CheckoutAPI.swift`, `Persistence`, `ViewModels`, then `Views`. The app entry point composes the practice screen; service implementations can be studied afterward.

The Xcode app compiles these sources directly. `Package.swift` compiles the same checkout models, services, persistence, and ViewModel separately for fast macOS tests; there is no duplicate implementation.

## Study material

- [LLD notes and diagrams](Docs/01-LLD-Notes.md)
- [HTTP API contract and backend responsibilities](Docs/02-API-Contract.md)
- [Interview questions with answers](Docs/03-Interview-QA.md)
- [Practice exercises](Docs/04-Practice-Exercises.md)

## Tests

Run **⌘U** with the app scheme in Xcode, or run the core tests from this folder:

```sh
swift test
```

Twelve tests cover persistent keys, rapid taps, timeout reconciliation, same-key retries, missing status after acceptance, polling limits, declines, request rejection, conflicts, mismatched responses, cancellation, and durable demo payment identity.

## Use the HTTP API

Switch on **Use local HTTP backend** before creating an order. The default base URL is `http://localhost:8080`, configured in `PracticeHomeView.swift`. The Go backend was not included in the pasted file; this project includes its expected client contract, not a Go implementation.

Simulator localhost points to the Mac. A physical phone needs the backend's reachable LAN host. The plist allows local networking; use HTTPS for nonlocal services. Real authentication, cart creation, gateway integration, and server reconciliation are outside this focused exercise.

## Deliberate limits

- One active order, one payment intent per order. A declined payment is terminal; a new attempt after decline needs an explicit backend contract.
- Demo price is ₹499.00; display assumes INR's two minor-unit decimal places. Do not divide all currencies by 100 in a general commerce app.
- UserDefaults is used for learning. Account scoping, logout cleanup, storage failures, schema migrations, and multi-device recovery need production design.
- Demo backend records are local simulation state, not evidence of a real charge. They accumulate so old order identities stay durable during practice.
- Client guards improve UX; the backend must prevent duplicate financial effects.

## Verification

Checked with Xcode 27.0 / Swift 6.4:

- macOS app build: passed.
- Generic iOS Simulator app build: passed.
- Xcode macOS test scheme: 12 tests passed, zero failures.
  
The iOS target was compiled; interactive iPhone simulator behavior and a real Go server were not exercised. Xcode's current XCTest emits a deployment-version linker warning for the macOS 13 test target; the tests pass on the installed macOS runtime.
