# POS Interview Lab

A small SwiftUI learning app for the PayPal **Sr Software Engineer, iOS — R0138411** role in Zettle SMB Direct. This is an independent practice project, not PayPal code or an integration with its systems.

## Start here

1. Clone this branch on your Mac.
2. Open `POSInterviewLab/POSInterviewLab.xcodeproj` (this project, not the older root project).
3. Select the **POSInterviewLab** scheme and an iPhone simulator with iOS 16 or later. Press Run.
4. A simulator needs no signing team. For a physical device, select your own development team in Signing & Capabilities.
5. No dependencies, API keys, Apple payment entitlements, card reader or backend installation are required.

The project was generated in a Linux environment. **Xcode compilation and simulator execution have not been verified.** Run the commands below on your Mac before relying on it.

```bash
cd POSInterviewLab
# Portable domain tests; opens separately as a Swift package in Xcode too.
swift test
# Build UI without device signing.
xcodebuild -project POSInterviewLab.xcodeproj -scheme POSInterviewLab \
  -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Tests live in the Swift package. They are not attached to the app scheme; run `swift test` or open Package.swift and select its test scheme.

## Three related labs

| Lab | Implemented | Learn |
| --- | --- | --- |
| Merchant checkout | Coffee quantity, integer minor units, approval, decline, unknown outcome, persisted lookup, receipt, full refund | Idempotency, reconciliation, actor isolation, immutable payment identity |
| Reader connectivity | Deterministic scan/discover/connect/ACK/disconnect state machine | Map familiar CoreBluetooth callbacks to POS readiness |
| Tap to Pay preparation | Fake merchant consent, expiring demo token, configuration gate | Separate onboarding, reader preparation and financial outcome |

Read [the gap map](Docs/01-Gap-Map.md), then the three lab READMEs in order:

1. [Checkout](Docs/02-Checkout-README.md)
2. [Reader connectivity](Docs/03-Reader-README.md)
3. [Tap to Pay and Key In](Docs/04-Tap-to-Pay-README.md)
4. [Interview questions](Docs/05-Interview-QA.md)
5. [Architecture decision and incident runbook](Docs/06-Architecture-and-Operations.md)
6. [Ten-session practice plan](Docs/07-Practice-Plan.md)

## First walkthrough: response lost after approval

1. Press **Advance reader / Disconnect** four times until `ready`.
2. Set scenario to `timeoutAfterApproval` and press **Pay — simulated**.
3. Observe `Outcome unknown`, disabled Pay and enabled status lookup.
4. Stop and relaunch the app. It should still require status lookup.
5. Press **Check payment status**. The fake server returns the original approval.
6. Verify the receipt and press **Full demo refund**.
7. Start a new sale and repeat with `declined`.

For Tap to Pay demo, switch method, accept demo terms and prepare the token. Expire the token to see the gate block payment. Token expiry is checked when Pay is pressed; the view has no countdown timer.

## Source reading order

- `Sources/POSCore/Payments.swift`: domain models, gateway protocol, fake server and reader state machine.
- `App/LabModel.swift`: main actor UI state and dependencies, pending payment recovery.
- `App/LabView.swift`: SwiftUI form and accessibility hooks.
- `Tests/POSCoreTests/PaymentTests.swift`: duplicate submission, payload conflict, restart recovery, refund and reader transition tests.

The app compiles the domain sources directly. The standalone package compiles the same files as POSCore for tests, avoiding third-party project generators.

## Explicit boundaries

All payments, tokens and reader events are simulated. There is no actual CoreBluetooth transport, ProximityReader session, PSP SDK, EMV processing, Key In card collection or network service. No PAN, PIN or CVV fields exist.

The fake server uses a local atomic JSON ledger. This demonstrates restart recovery, not a production backend. The client stores a pending UUID in UserDefaults; production needs a durable order/attempt journal with explicit persistence errors and reconciliation scheduling. Receipts are displayed after lookup, not a full persisted receipt history. Full refunds are synchronous and idempotent in the fake ledger; production refunds need their own pending state and reconciliation. The cart is one sample SKU; inventory, tax, tips, invoices, multi-merchant identity and partial refunds are exercises.

No real Tap to Pay capability is added: Apple requires a supported PSP and the appropriate entitlement. See [Apple Tap to Pay](https://developer.apple.com/tap-to-pay/) and [ProximityReader](https://developer.apple.com/documentation/proximityreader).
