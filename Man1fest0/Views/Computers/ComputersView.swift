import SwiftUI

struct ComputersView: View {
    @State var server: String
    @EnvironmentObject var networkController: NetBrain
    @EnvironmentObject var layout: Layout
    @EnvironmentObject var progress: Progress

    var body: some View {
        NavigationView {
            ComputersBasicView(server: server)
                .environmentObject(networkController)
                .environmentObject(layout)
                .environmentObject(progress)
            Text("Select a computer")
        }
    }
}
