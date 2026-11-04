# Lab 3 — Tap to Pay preparation and Key In design

## What runs

The app simulates consent, a 60-second token lifetime and configuration readiness. Tokens are represented only by an expiry Date. No Apple payment API is invoked. Merchant acceptance is educational UI, not Apple's actual terms flow.

## What real integration requires

Apple's Tap to Pay on iPhone lets a merchant accept contactless payments on a supported iPhone. It is distinct from integrating Apple Pay as a customer checkout button.

Work with a supported payment service provider, obtain Apple's Tap to Pay entitlement, and integrate the PSP SDK and/or ProximityReader according to that provider's certified flow. The provider supplies processing and certified terminal configuration. Verify current device, region, OS and account eligibility with Apple and the PSP rather than hardcoding assumptions from this demo.

Conceptual integration boundary:

1. Authenticate the merchant and select the correct merchant/location account.
2. Backend obtains the appropriate provider reader token; do not embed server API secrets in the app.
3. Check capability and present provider/Apple onboarding as required.
4. Prepare/configure the reader session; handle updates, expiry and cancellation.
5. Initiate a read through the certified API with amount and currency.
6. Submit the provider's opaque/encrypted result according to its contract.
7. Reconcile backend financial status before presenting payment success.

A prepared reader does not mean the issuer authorized a payment. A token is not a permanent login credential. On account switch invalidate the old session, tokens, cart ownership and caches; unresolved attempts must remain scoped to their original merchant.

## Key In

Key In is manually entering payment details, typically a different risk and processing path from card-present contactless/EMV. It is a role requirement and a documented extension here, not implemented UI.

Use PSP-supported collection/tokenization components and follow the provider/security team's integration guidance. Do not build PAN, PIN or CVV models just for this exercise. Do not log raw SDK payloads. Sensitive authentication data such as CVV or PIN must not be retained after authorization, even encrypted. Tokenization can reduce exposure but does not automatically remove PCI obligations.

## Glossary

- PAN: primary account number. Avoid handling it in app-owned state.
- EMV: chip/contactless payment specifications; not a BLE transport protocol.
- PSP: payment service provider, the processing/integration boundary.
- Reader token: provider-defined credential for reader preparation; lifecycle and storage depend on provider.
- Entitlement: Apple-granted capability; adding a string to a file does not grant permission.

## Primary references

- https://developer.apple.com/tap-to-pay/
- https://developer.apple.com/documentation/proximityreader
- https://www.pcisecuritystandards.org/standards/pci-dss/

Next implementation needs a chosen PSP sandbox and approved developer setup; this repo intentionally makes no unsupported promise that a simulator can accept real cards.
