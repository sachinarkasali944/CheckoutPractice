import Foundation

public enum Scenario: String, CaseIterable, Sendable {
    case approved, declined, timeoutAfterApproval
}
public enum PaymentStatus: String, Codable, Sendable { case approved, declined, refunded }
public struct Payment: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let amountMinor: Int
    public let method: String
    public var status: PaymentStatus
    public var displayAmount: String { String(format: "INR %.2f", Double(amountMinor) / 100) }
}
public enum PaymentError: Error { case invalidAmount, keyConflict, unknownPayment }
public protocol PaymentGateway: Sendable {
    func charge(key: UUID, amountMinor: Int, method: String, scenario: Scenario) async throws -> Payment
    func lookup(key: UUID) async throws -> Payment?
    func refund(key: UUID) async throws -> Payment
}

/// A persistent fake SERVER. No card data, credentials, or real money.
/// Actor isolation serializes this mock ledger. Production needs database transactions.
public actor DemoGateway: PaymentGateway {
    private var ledger: [String: Payment]
    private let file: URL
    public init(file: URL) throws {
        self.file = file
        if FileManager.default.fileExists(atPath: file.path) {
            ledger = try JSONDecoder().decode([String: Payment].self, from: Data(contentsOf: file))
        } else { ledger = [:] }
    }
    private func commit(_ next: [String: Payment]) throws {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(next).write(to: file, options: .atomic)
        ledger = next
    }
    public func charge(key: UUID, amountMinor: Int, method: String, scenario: Scenario) async throws -> Payment {
        guard amountMinor > 0 else { throw PaymentError.invalidAmount }
        if let existing = ledger[key.uuidString] {
            guard existing.amountMinor == amountMinor, existing.method == method else { throw PaymentError.keyConflict }
            return existing
        }
        let payment = Payment(id: key, amountMinor: amountMinor, method: method,
                              status: scenario == .declined ? .declined : .approved)
        var next = ledger
        next[key.uuidString] = payment
        try commit(next)
        // The server committed, but the client never received the response.
        if scenario == .timeoutAfterApproval { throw URLError(.timedOut) }
        return payment
    }
    public func lookup(key: UUID) async throws -> Payment? { ledger[key.uuidString] }
    public func refund(key: UUID) async throws -> Payment {
        guard var payment = ledger[key.uuidString], payment.status != .declined else { throw PaymentError.unknownPayment }
        if payment.status == .refunded { return payment }
        payment.status = .refunded
        var next = ledger
        next[key.uuidString] = payment
        try commit(next)
        return payment
    }
}

public enum ReaderState: String, Sendable { case disconnected, scanning, discovered, connecting, ready }
public struct ReaderMachine: Sendable {
    public private(set) var state: ReaderState = .disconnected
    public init() {}
    public mutating func scan() { if state == .disconnected { state = .scanning } }
    public mutating func discover() { if state == .scanning { state = .discovered } }
    public mutating func connect() { if state == .discovered { state = .connecting } }
    public mutating func acknowledge() { if state == .connecting { state = .ready } }
    public mutating func disconnect() { state = .disconnected }
}
