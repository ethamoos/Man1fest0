import SwiftUI

struct PolicyConcurrencyPreferencesView: View {
    @EnvironmentObject var networkController: NetBrain
    @State private var concurrencyValue: Int = 4
    @State private var showSavedToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Policy fetch concurrency")
                .font(.headline)

            HStack {
                Stepper(value: $concurrencyValue, in: 1...16, step: 1) {
                    Text("\(concurrencyValue) concurrent requests")
                }
                .help("Set how many policy detail requests the app will run at the same time. Recommended: 1–4.")
                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    networkController.setPolicyFetchConcurrency(concurrencyValue)
                    showSavedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showSavedToast = false
                    }
                }) {
                    Text("Save")
                }

                Button(action: {
                    concurrencyValue = networkController.getPolicyFetchConcurrency()
                }) {
                    Text("Reset to current")
                }

                Spacer()

                Text("Current: \(networkController.policyFetchConcurrency)")
                    .foregroundColor(.secondary)
            }

            if showSavedToast {
                Text("Saved")
                    .foregroundColor(.green)
            }

            Divider()

            if concurrencyValue > 8 {
                Text("Warning: Values above 8 may overload some Jamf servers or cause rate-limiting.")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }

            Text("Tip: Increasing concurrency may make fetching policies faster but may also increase load on the Jamf server. Recommended: 1–4.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .onAppear {
            concurrencyValue = networkController.getPolicyFetchConcurrency()
        }
        .frame(minWidth: 400, minHeight: 140)
    }
}

struct PolicyConcurrencyPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PolicyConcurrencyPreferencesView()
            .environmentObject(NetBrain())
    }
}
