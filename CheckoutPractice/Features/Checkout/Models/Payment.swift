import Foundation

enum PaymentStatus: String, Codable, Sendable {
    case processing = "PROCESSING"
    case succeeded = "SUCCEEDED"
    case failed = "FAILED"
}

struct Payment: Codable, Sendable {
    let id: String
    let orderID: String
    let amountMinor: Int64
    let currency: String
    let status: PaymentStatus
}
