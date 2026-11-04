import SwiftUI

struct LabView: View {
    @StateObject private var model = LabModel()
    var body: some View {
        NavigationStack {
            Form {
                Section("Learning sandbox — no real payments") {
                    Text("Coffee shop POS · INR · iOS 16+")
                    Text(model.message).accessibilityIdentifier("paymentStatus")
                    if model.busy { ProgressView("Processing") }
                }
                Section("1 · Reader connectivity simulator") {
                    Text("Reader: \(model.reader.state.rawValue)")
                    Button("Advance reader / Disconnect") { model.readerAction() }.disabled(model.busy)
                    Text("Disconnected → scanning → discovered → connecting → ready. Each tap advances one simulated callback.")
                        .font(.caption)
                }
                Section("2 · Tap to Pay preparation simulator") {
                    Toggle("Demo merchant accepts terms", isOn: $model.merchantAccepted).disabled(model.busy)
                    Button("Issue demo token and configure") { model.prepareTap() }.disabled(!model.merchantAccepted || model.busy)
                    Button("Expire demo token") { model.expireToken() }.disabled(model.busy)
                    Text(model.tapPrepared ? "Demo configuration prepared; token lasts 60 seconds." : "Demo configuration required.")
                }
                Section("3 · Checkout") {
                    Stepper("Coffee × \(model.quantity)", value: Binding(get: { model.quantity }, set: { model.changeQuantity($0) }), in: 1...10)
                        .disabled(!model.canEdit)
                    Text("Total: \(Double(model.amountMinor) / 100, format: .currency(code: "INR"))")
                    Picker("Method", selection: $model.method) {
                        Text("Reader").tag("Reader")
                        Text("Tap to Pay demo").tag("Tap to Pay demo")
                    }.disabled(!model.canEdit)
                    Picker("Server scenario", selection: $model.scenario) {
                        ForEach(Scenario.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.disabled(!model.canEdit)
                    Button("Pay — simulated") { Task { await model.pay() } }.disabled(!model.canPay)
                    Button("Check payment status") { Task { await model.recover() } }.disabled(!model.hasPending || model.busy)
                }
                if let payment = model.payment {
                    Section("Receipt") {
                        Text(payment.displayAmount)
                        Text(payment.status.rawValue.capitalized)
                        Text("Receipt: \(payment.id.uuidString)").font(.caption).textSelection(.enabled)
                        Text("Method: \(payment.method)")
                        Button("Full demo refund") { Task { await model.refund() } }.disabled(payment.status != .approved || model.busy)
                        Button("New sale") { model.newSale() }.disabled(model.busy)
                    }
                }
                Section("Sanitized diagnostic events") {
                    ForEach(Array(model.events.enumerated()), id: \.offset) { _, event in Text(event).font(.caption.monospaced()) }
                }
            }.navigationTitle("POS Interview Lab")
        }
    }
}
