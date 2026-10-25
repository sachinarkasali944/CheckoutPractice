import XCTest
#if SWIFT_PACKAGE
@testable import CheckoutCore
#else
@testable import CheckoutPractice
#endif

private actor StubAPI: CheckoutAPI {
    enum Start: Sendable { case processing, lostResponse, rejected, conflict, mismatchedSuccess }
    private let start: Start
    private let statuses: [PaymentStatus]
    private let missing: Bool
    private var reads = 0
    private var keys: [String] = []

    init(start: Start = .processing, statuses: [PaymentStatus] = [.succeeded], missing: Bool = false) {
        self.start = start
        self.statuses = statuses
        self.missing = missing
    }
    func createOrder() async throws -> Order { Self.order }
    static var order: Order { Order(id: "order-1", amountMinor: 49_900, currency: "INR", status: .created) }
    func startPayment(orderID: String, key: String) async throws -> Payment {
        keys.append(key)
        switch start {
        case .lostResponse: throw URLError(.timedOut)
        case .rejected: throw APIError.http(422)
        case .conflict: throw APIError.http(409)
        case .mismatchedSuccess:
            return Payment(id: "p1", orderID: "another-order", amountMinor: 49_900,
                           currency: "INR", status: .succeeded)
        case .processing: return payment(.processing)
        }
    }
    func getPayment(orderID: String) async throws -> Payment {
        reads += 1
        if missing { throw APIError.http(404) }
        return payment(statuses[min(reads - 1, statuses.count - 1)])
    }
    private func payment(_ status: PaymentStatus) -> Payment {
        Payment(id: "p1", orderID: "order-1", amountMinor: 49_900, currency: "INR", status: status)
    }
    func submittedKeys() -> [String] { keys }
    func lookupCount() -> Int { reads }
}

@MainActor
final class CheckoutTests: XCTestCase {
    private func store() -> PaymentKeyStore {
        let defaults = UserDefaults(suiteName: "checkout.tests.\(UUID().uuidString)")!
        return PaymentKeyStore(defaults: defaults)
    }
    private func model(_ api: StubAPI, attempts: Int = 3, delay: UInt64 = 0) -> CheckoutViewModel {
        CheckoutViewModel(order: StubAPI.order, api: api, keyStore: store(),
                          pollAttempts: attempts, pollDelay: delay)
    }

    func testKeySurvivesStoreRecreationAndIsScopedPerOrder() {
        let defaults = UserDefaults(suiteName: "checkout.keys.\(UUID().uuidString)")!
        let first = PaymentKeyStore(defaults: defaults).key(for: "o1")
        XCTAssertEqual(first, PaymentKeyStore(defaults: defaults).key(for: "o1"))
        XCTAssertNotEqual(first, PaymentKeyStore(defaults: defaults).key(for: "o2"))
    }

    func testRepeatedTapsSubmitOnlyOnceAndConfirmFromBackend() async {
        let api = StubAPI(statuses: [.processing, .succeeded])
        let vm = model(api)
        vm.pay()
        vm.pay()
        XCTAssertEqual(vm.state, .submitting)
        await vm.waitForObservation()
        let keys = await api.submittedKeys()
        XCTAssertEqual(keys.count, 1)
        XCTAssertEqual(vm.state, .succeeded)
    }

    func testLostResponseReconcilesToSuccess() async {
        let vm = model(StubAPI(start: .lostResponse))
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .succeeded)
    }

    func testMissingPaymentAllowsRetryWithSameKey() async {
        let api = StubAPI(start: .lostResponse, missing: true)
        let vm = model(api)
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .ready)
        vm.pay()
        await vm.waitForObservation()
        let keys = await api.submittedKeys()
        XCTAssertEqual(keys.count, 2)
        XCTAssertEqual(keys.first, keys.last)
    }

    func test404AfterAcceptanceDoesNotEnableAnotherPayment() async {
        let vm = model(StubAPI(missing: true))
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .unknown)
        XCTAssertFalse(vm.canPay)
    }

    func testPollingBudgetExhaustionMeansUnknown() async {
        let api = StubAPI(statuses: [.processing])
        let vm = model(api, attempts: 2)
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .unknown)
        let reads = await api.lookupCount()
        XCTAssertEqual(reads, 2)
    }

    func testBackendDeclineIsTerminal() async {
        let vm = model(StubAPI(statuses: [.failed]))
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .failed)
        XCTAssertFalse(vm.canPay)
    }

    func testRejectionIsDifferentFromDecline() async {
        let api = StubAPI(start: .rejected)
        let vm = model(api)
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .rejected)
        let reads = await api.lookupCount()
        XCTAssertEqual(reads, 0)
    }

    func testConflictReconcilesExistingPayment() async {
        let vm = model(StubAPI(start: .conflict))
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .succeeded)
    }

    func testMismatchedSuccessNeverDisplaysSuccess() async {
        let vm = model(StubAPI(start: .mismatchedSuccess))
        vm.pay()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .unknown)
    }

    func testCancellationStopsObservationWithoutClaimingFailure() async {
        let vm = model(StubAPI(statuses: [.processing]), delay: 60_000_000_000)
        vm.pay()
        vm.stopObserving()
        await vm.waitForObservation()
        XCTAssertEqual(vm.state, .unknown)
    }

    func testDemoServerReusesPaymentAndRecoversAcrossInstances() async throws {
        let suite = "checkout.backend.\(UUID().uuidString)"
        let first = DemoCheckoutAPI(suiteName: suite)
        let order = try await first.createOrder()
        let payment = try await first.startPayment(orderID: order.id, key: "stable-key")
        let second = DemoCheckoutAPI(suiteName: suite)
        let retry = try await second.startPayment(orderID: order.id, key: "stable-key")
        XCTAssertEqual(payment.id, retry.id)
        do {
            _ = try await second.startPayment(orderID: order.id, key: "different-key")
            XCTFail("Expected conflicting key rejection")
        } catch APIError.http(409) { }
    }
}
