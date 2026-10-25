import Foundation

// Demo identifiers are not secrets. Scope by account in a signed-in app.
@MainActor
final class PaymentKeyStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func key(for orderID: String) -> String {
        let storageKey = "payment.key.\(orderID)"

        if let existing = defaults.string(forKey: storageKey) {
            return existing
        }

        let newKey = UUID().uuidString
        defaults.set(newKey, forKey: storageKey)
        return newKey
    }
}
