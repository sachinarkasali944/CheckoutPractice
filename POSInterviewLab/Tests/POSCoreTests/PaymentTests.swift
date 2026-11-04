import XCTest
@testable import POSCore

final class PaymentTests: XCTestCase {
    func makeGateway() throws -> (DemoGateway, URL) {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("ledger.json")
        return (try DemoGateway(file: file), file)
    }
    func testTimeoutCanBeRecoveredAfterServerRestart() async throws {
        let (gateway, file) = try makeGateway()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let key = UUID()
        do {
            _ = try await gateway.charge(key: key, amountMinor: 15000, method: "Reader", scenario: .timeoutAfterApproval)
            XCTFail("Expected response loss")
        } catch let error as URLError { XCTAssertEqual(error.code, .timedOut) }
        let restarted = try DemoGateway(file: file)
        let recovered = try await restarted.lookup(key: key)
        XCTAssertEqual(recovered?.status, .approved)
    }
    func testConcurrentDuplicateRequestsReturnSamePayment() async throws {
        let (gateway, file) = try makeGateway()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let key = UUID()
        async let a = gateway.charge(key: key, amountMinor: 15000, method: "Reader", scenario: .approved)
        async let b = gateway.charge(key: key, amountMinor: 15000, method: "Reader", scenario: .approved)
        let (first, second) = try await (a, b)
        XCTAssertEqual(first, second)
    }
    func testChangedPayloadRejectsReusedKey() async throws {
        let (gateway, file) = try makeGateway()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let key = UUID()
        _ = try await gateway.charge(key: key, amountMinor: 100, method: "Reader", scenario: .approved)
        do {
            _ = try await gateway.charge(key: key, amountMinor: 200, method: "Reader", scenario: .approved)
            XCTFail("Expected key conflict")
        } catch PaymentError.keyConflict {} catch { XCTFail("Unexpected error: \(error)") }
    }
    func testRefundIsRepeatableAndDeclineIsNotRefundable() async throws {
        let (gateway, file) = try makeGateway()
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let key = UUID()
        _ = try await gateway.charge(key: key, amountMinor: 100, method: "Reader", scenario: .approved)
        let first = try await gateway.refund(key: key)
        let second = try await gateway.refund(key: key)
        XCTAssertEqual(first, second)
        XCTAssertEqual(second.status, .refunded)
        let declined = UUID()
        _ = try await gateway.charge(key: declined, amountMinor: 100, method: "Reader", scenario: .declined)
        do { _ = try await gateway.refund(key: declined); XCTFail("Cannot refund decline") }
        catch PaymentError.unknownPayment {} catch { XCTFail("Unexpected error") }
    }
    func testReaderRejectsOutOfOrderAcknowledgment() {
        var reader = ReaderMachine()
        reader.acknowledge()
        XCTAssertEqual(reader.state, .disconnected)
        reader.scan(); reader.discover(); reader.connect(); reader.acknowledge()
        XCTAssertEqual(reader.state, .ready)
        reader.disconnect()
        XCTAssertEqual(reader.state, .disconnected)
    }
}
