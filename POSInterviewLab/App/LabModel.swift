import Foundation
import Combine

@MainActor
final class LabModel: ObservableObject {
    @Published var scenario: Scenario = .approved
    @Published var method = "Reader"
    @Published private(set) var quantity = 1
    @Published private(set) var payment: Payment?
    @Published private(set) var message = "Add coffee and choose a payment method."
    @Published private(set) var busy = false
    @Published private(set) var reader = ReaderMachine()
    @Published private(set) var tapPrepared = false
    @Published var merchantAccepted = false
    @Published private(set) var events: [String] = []
    private let gateway: (any PaymentGateway)?
    private let defaults: UserDefaults
    private var tokenExpiry: Date?
    private var pending: UUID?
    var amountMinor: Int { quantity * 15000 }
    var hasPending: Bool { pending != nil }
    var canEdit: Bool { !busy && !hasPending && payment == nil }
    var canPay: Bool { canEdit && gateway != nil && (method == "Reader" ? reader.state == .ready : tapPrepared && (tokenExpiry ?? .distantPast) > Date()) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        do {
            let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            gateway = try DemoGateway(file: root.appendingPathComponent("POSLab/fake-server.json"))
        } catch { gateway = nil; message = "Cannot load demo ledger: \(error.localizedDescription)" }
        if let raw = defaults.string(forKey: "POSLab.pending"), let key = UUID(uuidString: raw) {
            pending = key
            message = "Unresolved payment. Check status before a new sale."
        }
    }
    func changeQuantity(_ value: Int) { guard canEdit else { return }; quantity = min(10, max(1, value)) }
    func readerAction() {
        guard !busy else { return }
        switch reader.state {
        case .disconnected: reader.scan()
        case .scanning: reader.discover()
        case .discovered: reader.connect()
        case .connecting: reader.acknowledge()
        case .ready: reader.disconnect()
        }
        log("reader_\(reader.state.rawValue)")
    }
    func prepareTap() {
        guard merchantAccepted, !busy else { return }
        tokenExpiry = Date().addingTimeInterval(60)
        tapPrepared = true
        log("tap_demo_configuration_ready")
    }
    func expireToken() { tokenExpiry = nil; tapPrepared = false; log("tap_demo_token_expired") }
    func pay() async {
        guard canPay, let gateway else { return }
        busy = true // Set before await: block reentrant taps.
        defer { busy = false }
        let key = UUID()
        pending = key
        defaults.set(key.uuidString, forKey: "POSLab.pending")
        let amount = amountMinor
        let selectedMethod = method
        let selectedScenario = scenario
        message = "Processing simulated payment..."
        log("payment_started")
        do {
            try Task.checkCancellation()
            let result = try await gateway.charge(key: key, amountMinor: amount, method: selectedMethod, scenario: selectedScenario)
            finish(result)
        } catch {
            // Includes cancellation: the client cannot infer server outcome.
            message = "Outcome unknown. Check payment status."
            log("payment_unknown")
        }
    }
    func recover() async {
        guard !busy, let key = pending, let gateway else { return }
        busy = true
        defer { busy = false }
        do {
            if let result = try await gateway.lookup(key: key) { finish(result) }
            else {
                // This fake server has immediate, authoritative lookup.
                // Real APIs may return pending/eventual consistency: keep reconciling.
                clearPending()
                message = "Demo server confirms no payment. You may start again."
            }
        } catch { message = "Status unavailable. Keep this sale pending." }
    }
    func refund() async {
        guard !busy, let current = payment, current.status == .approved, let gateway else { return }
        busy = true
        defer { busy = false }
        do { payment = try await gateway.refund(key: current.id); message = "Full demo refund completed."; log("refund_completed") }
        catch { message = "Refund failed; check status before retrying." }
    }
    func newSale() {
        guard !busy, !hasPending else { return }
        payment = nil; quantity = 1; message = "New sale."
    }
    private func finish(_ result: Payment) {
        payment = result
        clearPending()
        message = "Payment \(result.status.rawValue)."
        log("payment_\(result.status.rawValue)")
    }
    private func clearPending() { pending = nil; defaults.removeObject(forKey: "POSLab.pending") }
    private func log(_ event: String) { events.insert(event, at: 0); events = Array(events.prefix(20)) }
}
