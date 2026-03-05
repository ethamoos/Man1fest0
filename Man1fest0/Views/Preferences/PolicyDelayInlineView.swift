import SwiftUI

struct PolicyDelayInlineView: View {
    @EnvironmentObject var networkController: NetBrain
    @State private var delayValue: Double = 0.0

    var body: some View {
        VStack(alignment: .leading) {
            Slider(value: $delayValue, in: 0...60, step: 0.1)
            HStack {
                Button("Save") {
                    networkController.setPolicyRequestDelay(delayValue)
                }
                Button("Reset") {
                    delayValue = networkController.getPolicyRequestDelay()
                }
                Spacer()
                Text(networkController.humanReadableDuration(delayValue))
            }
            .onAppear { delayValue = networkController.getPolicyRequestDelay() }
        }
    }
}

struct PolicyDelayInlineView_Previews: PreviewProvider {
    static var previews: some View {
        PolicyDelayInlineView().environmentObject(NetBrain())
    }
}
