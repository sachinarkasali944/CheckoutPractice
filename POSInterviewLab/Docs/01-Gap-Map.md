# Role gap map

Based on the supplied role description and resume. A resume omission means an area to validate, not proof of missing experience.

| Requirement | Evidence you already have | Focus here |
| --- | --- | --- |
| Hardware-connected iOS | Bosch GLL/GCL/GRL, CoreBluetooth, auto reconnect | Explain how a transport ACK differs from payment approval |
| Modular architecture | MVVM, protocol framework, URLSession | PaymentGateway boundary and state ownership |
| Concurrency | Swift Concurrency | MainActor reentrancy, fake server actor and concurrent duplicates |
| Tap to Pay / ProximityReader | Not stated in resume | Entitlement, PSP token and certified configuration lifecycle |
| Payment lifecycle / EMV | Not stated | Authorization, capture, settlement, declines and ambiguous results |
| PCI-aware design | Not stated | Keep card data outside application models, logs and analytics |
| Testing critical flows | XCTest experience | Restart recovery, duplicate submissions and refund invariants |
| Releases and operations | TestFlight, App Store, Azure DevOps | Merchant impact, rollout metrics, kill switches and runbooks |
| Leadership / handover | End-to-end ownership | Architecture decisions, review standards and Sweden handover |

Interview bridge: “At Bosch I isolated device-specific protocol behavior behind an interface and handled unstable connectivity. In this independent POS lab I applied that experience to reader readiness, then learned the additional financial requirement: a lost response must be reconciled before another charge.”

Do not claim this lab is production payments experience or a real PSP integration. Describe the implemented simulation and its limits precisely.
