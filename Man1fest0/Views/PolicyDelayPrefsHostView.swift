import SwiftUI

struct PolicyDelayPrefsHostView: View {
    @EnvironmentObject var networkController: NetBrain
    @State private var delayValue: Double = 0.0
    @State private var showSavedToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Policy fetch delay (seconds)")
                .font(.headline)

            HStack {
                Slider(value: $delayValue, in: 0...10, step: 0.1)
                Stepper(value: $delayValue, in: 0...60, step: 1) {
                    Text("\(Int(delayValue)) s")
                        .frame(minWidth: 60)
                }
            }

            HStack(spacing: 12) {
                Button(action: {
                    networkController.setPolicyRequestDelay(delayValue)
                    showSavedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSavedToast = false
                    }
                }) {
                    Text("Save")
                }

                Button(action: {
                    delayValue = networkController.getPolicyRequestDelay()
                }) {
                    Text("Reset to current")
                }

                Spacer()

                Text(networkController.policyDelayStatus)
                    .foregroundColor(.secondary)
            }

            if showSavedToast {
                Text("Saved")
                    .foregroundColor(.green)
            }

            Divider()

            Text("Human readable: \(networkController.humanReadableDuration(delayValue))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .onAppear {
            delayValue = networkController.getPolicyRequestDelay()
        }
        .frame(minWidth: 400, minHeight: 160)
    }
}

struct PolicyDelayPrefsHostView_Previews: PreviewProvider {
    static var previews: some View {
        PolicyDelayPrefsHostView()
            .environmentObject(NetBrain())
    }
}
