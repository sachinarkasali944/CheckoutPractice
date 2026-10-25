import SwiftUI

@MainActor
struct CheckoutView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: CheckoutViewModel

    init(order: Order, api: any CheckoutAPI) {
        _viewModel = StateObject(
            wrappedValue: CheckoutViewModel(
                order: order,
                api: api,
                keyStore: PaymentKeyStore()
            )
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Order \(viewModel.order.id)")
                .font(.headline)

            // This exercise fixes INR to two minor-unit decimal places.
            Text(
                (Double(viewModel.order.amountMinor) / 100)
                    .formatted(
                        .currency(
                            code: viewModel.order.currency
                        )
                    )
            )

            switch viewModel.state {
            case .ready:
                Button("Pay") {
                    viewModel.pay()
                }
                .buttonStyle(.borderedProminent)

            case .submitting:
                ProgressView("Submitting payment…")

            case .processing:
                ProgressView("Confirming payment…")

            case .succeeded:
                Label(
                    "Payment successful",
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(.green)

            case .failed:
                Text("Payment declined")
                    .foregroundStyle(.red)

            case .unknown:
                Text("Payment confirmation is pending.")

                Button("Check status") {
                    viewModel.refreshStatus()
                }

            case .rejected:
                Text("Payment request could not be accepted.")

                Button("Check status") {
                    viewModel.refreshStatus()
                }
            }
        }
        .padding()
        .task {
            // Also discovers an existing payment after reopening.
            viewModel.refreshStatus()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { viewModel.refreshStatus() }
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
}
