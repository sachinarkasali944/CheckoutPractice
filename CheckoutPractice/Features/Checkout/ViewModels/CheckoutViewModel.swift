import Foundation
import Combine

enum CheckoutState: Equatable {
    case ready
    case submitting
    case processing
    case succeeded
    case failed
    case unknown
    case rejected
}

// MARK: ViewModel

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published private(set) var state: CheckoutState = .ready

    let order: Order

    private let api: any CheckoutAPI
    private let keyStore: PaymentKeyStore

    private var task: Task<Void, Never>?
    private let pollAttempts: Int
    private let pollDelay: UInt64
    private var hasObservedPayment: Bool

    init(
        order: Order,
        api: any CheckoutAPI,
        keyStore: PaymentKeyStore,
        pollAttempts: Int = 10,
        pollDelay: UInt64 = 2_000_000_000
    ) {
        self.order = order
        self.api = api
        self.keyStore = keyStore
        self.pollAttempts = max(1, pollAttempts)
        self.pollDelay = pollDelay
        self.hasObservedPayment = order.status != .created

        switch order.status {
        case .created:
            state = .ready
        case .paymentPending:
            state = .processing
        case .paid:
            state = .succeeded
        case .paymentFailed:
            state = .failed
        }
    }

    var canPay: Bool {
        if case .ready = state {
            return true
        }
        return false
    }

    func pay() {
        guard canPay, task == nil else {
            return
        }

        state = .submitting

        // Generated before submitting and reused afterward.
        let key = keyStore.key(for: order.id)

        task = Task { [weak self] in
            guard let self else { return }
            defer { self.task = nil }

            do {
                let payment = try await self.api.startPayment(
                    orderID: self.order.id,
                    key: key
                )

                if self.apply(payment) {
                    return
                }
            } catch {
                if Task.isCancelled {
                    self.state = .unknown
                    return
                }

                // Only these codes are defined as pre-payment rejections in this demo.
                // 408, 409 and 429 are ambiguous; reconcile their status.
                if case APIError.http(let code) = error,
                   [400, 401, 403, 422].contains(code) {
                    self.state = .rejected
                    return
                }

                // Timeout, decoding failure, or 5xx:
                // the backend may already have accepted payment.
                self.state = .processing
            }

            await self.pollStatus()
        }
    }

    // Call after returning to checkout, or from "Check status".
    func refreshStatus() {
        guard task == nil else {
            return
        }

        switch state {
        case .succeeded, .failed, .submitting:
            return
        default:
            break
        }

        state = .processing

        task = Task { [weak self] in
            guard let self else { return }
            defer { self.task = nil }

            await self.pollStatus()
        }
    }

    // Useful for deterministic tests and callers awaiting the current observation.
    func waitForObservation() async {
        await task?.value
    }

    // Stopping observation never cancels the backend payment.
    func stopObserving() {
        task?.cancel()
    }

    private func pollStatus() async {
        // Bounded polling for the demo.
        // Backend reconciliation continues after this finishes.
        for attempt in 0..<pollAttempts {
            guard !Task.isCancelled else {
                state = .unknown
                return
            }

            do {
                let payment = try await api.getPayment(
                    orderID: order.id
                )

                if apply(payment) {
                    return
                }
            } catch {
                if Task.isCancelled {
                    state = .unknown
                    return
                }

                if case APIError.http(404) = error, !hasObservedPayment {
                    // Start request may never have reached the server.
                    // Allow another submission using the SAME key.
                    state = .ready
                    return
                }

                // Transient lookup errors keep the outcome unknown.
            }

            guard attempt + 1 < pollAttempts else { break }
            do {
                try await Task.sleep(
                    nanoseconds: pollDelay
                )
            } catch {
                state = .unknown
                return
            }
        }

        state = .unknown
    }

    // Returns true when the backend reports a terminal state.
    private func apply(_ payment: Payment) -> Bool {
        guard payment.orderID == order.id,
              payment.amountMinor == order.amountMinor,
              payment.currency == order.currency else {
            state = .unknown
            return true // Stop observing an invalid response; never show success.
        }
        hasObservedPayment = true
        switch payment.status {
        case .processing:
            state = .processing
            return false

        case .succeeded:
            state = .succeeded
            return true

        case .failed:
            state = .failed
            return true
        }
    }
}
