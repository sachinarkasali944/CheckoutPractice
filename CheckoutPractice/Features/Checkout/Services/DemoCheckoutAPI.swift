import Foundation

enum DemoScenario: String, CaseIterable, Identifiable, Codable, Sendable {
    case success = "Payment succeeds"
    case lostResponse = "Response lost, payment succeeds"
    case decline = "Payment declined"
    case pending = "Confirmation stays pending"
    case rejected = "Request rejected (422)"
    var id: String { rawValue }
}

// An in-process server simulator, not a payment gateway. Its durable records let
// the exercise demonstrate app relaunch recovery. Actor isolation serializes access.
actor DemoCheckoutAPI: CheckoutAPI {
    private struct Record: Codable {
        let order: Order
        let scenario: DemoScenario
        var key: String?
        var paymentID: String?
        var startedAt: Date?
    }
    private var records: [String: Record]
    private let defaults: UserDefaults
    private let scenario: DemoScenario
    private let storageKey = "demo.backend.records.v1"

    init(scenario: DemoScenario = .success, suiteName: String? = nil) {
        self.scenario = scenario
        let defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        self.defaults = defaults
        self.records = defaults.data(forKey: "demo.backend.records.v1")
            .flatMap { try? JSONDecoder().decode([String: Record].self, from: $0) } ?? [:]
    }

    func createOrder() async throws -> Order {
        let order = Order(id: UUID().uuidString, amountMinor: 49_900,
                          currency: "INR", status: .created)
        records[order.id] = Record(order: order, scenario: scenario)
        persist()
        return order
    }

    func startPayment(orderID: String, key: String) async throws -> Payment {
        guard var record = records[orderID] else { throw APIError.http(404) }
        guard record.scenario != .rejected else { throw APIError.http(422) }
        if let existingKey = record.key {
            guard existingKey == key else { throw APIError.http(409) }
            return payment(from: record)
        }
        record.key = key
        record.paymentID = UUID().uuidString
        record.startedAt = Date()
        records[orderID] = record
        persist() // Acceptance happens before a simulated lost response.
        if record.scenario == .lostResponse { throw URLError(.timedOut) }
        return payment(from: record)
    }

    func getPayment(orderID: String) async throws -> Payment {
        guard let record = records[orderID], record.paymentID != nil else {
            throw APIError.http(404)
        }
        return payment(from: record)
    }

    private func payment(from record: Record) -> Payment {
        let elapsed = Date().timeIntervalSince(record.startedAt ?? Date())
        let status: PaymentStatus = elapsed < 3 || record.scenario == .pending
            ? .processing : (record.scenario == .decline ? .failed : .succeeded)
        return Payment(id: record.paymentID!, orderID: record.order.id,
                       amountMinor: record.order.amountMinor,
                       currency: record.order.currency, status: status)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: storageKey) }
    }
}
