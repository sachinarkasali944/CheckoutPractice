import SwiftUI

@MainActor
struct PracticeHomeView: View {
    @AppStorage("checkout.active.order.v1") private var savedOrder = Data()
    @AppStorage("checkout.active.live.v1") private var savedLiveMode = false
    @State private var scenario: DemoScenario = .success
    @State private var liveMode = false
    @State private var activeOrder: Order?
    @State private var api: (any CheckoutAPI)?
    @State private var isCreating = false
    @State private var errorMessage: String?

    // Edit this URL when connecting the supplied Go API. Device builds need a LAN host.
    private let backendURL = URL(string: "http://localhost:8080")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Reliable checkout").font(.largeTitle.bold())
                    Text("LLD practice • one order, one payment intent")
                        .foregroundStyle(.secondary)
                    if let activeOrder, let api {
                        CheckoutView(order: activeOrder, api: api)
                            .id(activeOrder.id)
                        Button("Leave order and start another") {
                            self.activeOrder = nil
                            self.api = nil
                            savedOrder = Data()
                        }
                        Text("Leaving this screen does not cancel a payment. Its saved backend record remains.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Toggle("Use local HTTP backend", isOn: $liveMode)
                        if !liveMode {
                            Picker("Demo scenario", selection: $scenario) {
                                ForEach(DemoScenario.allCases) { Text($0.rawValue).tag($0) }
                            }
                        }
                        Text(liveMode ? "Backend: \(backendURL.absoluteString)" : "Demo order: ₹499.00 • no real money")
                        Button(isCreating ? "Creating order…" : "Create order") {
                            Task { await createOrder() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isCreating)
                    }
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                }
                .padding(24)
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .task {
                guard activeOrder == nil,
                      let restored = try? JSONDecoder().decode(Order.self, from: savedOrder) else { return }
                activeOrder = restored
                liveMode = savedLiveMode
                api = makeAPI(live: savedLiveMode)
            }
        }
        .frame(minWidth: 340, minHeight: 480)
    }

    private func makeAPI(live: Bool) -> any CheckoutAPI {
        live ? HTTPCheckoutAPI(baseURL: backendURL) : DemoCheckoutAPI(scenario: scenario)
    }

    private func createOrder() async {
        guard !isCreating else { return }
        isCreating = true
        errorMessage = nil
        defer { isCreating = false }
        do {
            let selectedAPI = makeAPI(live: liveMode)
            let order = try await selectedAPI.createOrder()
            savedOrder = try JSONEncoder().encode(order)
            savedLiveMode = liveMode
            api = selectedAPI
            activeOrder = order
        } catch {
            errorMessage = "Could not create order: \(error.localizedDescription)"
        }
    }
}
