import Foundation

protocol CheckoutAPI: Sendable {
    func createOrder() async throws -> Order

    func startPayment(
        orderID: String,
        key: String
    ) async throws -> Payment

    func getPayment(orderID: String) async throws -> Payment
}

enum APIError: Error {
    case mismatchedPayment
    case invalidResponse
    case http(Int)
}
