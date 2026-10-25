import Foundation

struct HTTPCheckoutAPI: CheckoutAPI {
    let baseURL: URL
    var session: URLSession = .shared

    func createOrder() async throws -> Order {
        try await request(
            path: "orders",
            method: "POST"
        )
    }

    func startPayment(
        orderID: String,
        key: String
    ) async throws -> Payment {
        try await request(
            path: "orders/\(orderID)/payment",
            method: "POST",
            key: key
        )
    }

    func getPayment(orderID: String) async throws -> Payment {
        try await request(
            path: "orders/\(orderID)/payment",
            method: "GET"
        )
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        key: String? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10

        if let key {
            request.setValue(
                key,
                forHTTPHeaderField: "Idempotency-Key"
            )
        }

        let (data, response) = try await session.data(
            for: request
        )

        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(response.statusCode) else {
            throw APIError.http(response.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
