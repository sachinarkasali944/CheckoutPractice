import Foundation

enum OrderStatus: String, Codable, Sendable {
    case created = "CREATED"
    case paymentPending = "PAYMENT_PENDING"
    case paid = "PAID"
    case paymentFailed = "PAYMENT_FAILED"
}

struct Order: Codable, Sendable {
    let id: String
    let amountMinor: Int64
    let currency: String
    let status: OrderStatus
}
