# Lab 2 — Reader connectivity

The implemented reader is a deterministic simulator. Every button press represents one callback; it does not scan the radio or pair a real payment reader.

| Demo event | CoreBluetooth equivalent you know | Payment-specific caution |
| --- | --- | --- |
| scan | central powered-on check, scanForPeripherals | Use documented vendor discovery filters |
| discover | didDiscover with retained peripheral | Discovery is not authentication |
| connect | connect and didConnect | Link establishment is not financial readiness |
| acknowledge | Service discovery and vendor handshake complete | Ready only after PSP/vendor configuration succeeds |
| disconnect | didDisconnectPeripheral | Keep any payment outcome unresolved until reconciled |

## Bring your Bosch experience

Discuss retained peripherals, service/characteristic discovery, notifications, MTU-sized chunks, ACK correlation, timeouts, reconnect backoff and cancelling stale operations. Avoid inventing reader UUIDs or a payment protocol. Commercial payment readers usually require the provider's certified integration; a generic BLE scanner cannot turn arbitrary hardware into a payment terminal.

## Why explicit states?

A single `isConnected` Boolean cannot distinguish discovering, authenticating, updating firmware and ready. This machine rejects out-of-order acknowledgments. In production add operation/session IDs so a late callback from an old connection cannot mark a new session ready.

## Exercises

1. Add `failed(reason)` and a bounded connection timeout using an injected clock.
2. Introduce a ReaderTransport protocol with simulated and vendor-SDK implementations.
3. Model disconnect during payment: reader becomes disconnected while payment becomes unknown; one state must not overwrite the other.
4. Reconnect with exponential backoff and jitter; stop when user cancels or Bluetooth is unauthorized/off.
5. Test a late ACK after disconnect and a stale ACK after a new connection starts.

CoreBluetooth reference: https://developer.apple.com/documentation/corebluetooth
