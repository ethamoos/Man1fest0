import SwiftUI

// Lightweight inline preferences view to ensure it's always in-scope for the App
#if os(macOS)
fileprivate struct AppPolicyDelayPreferencesView: View {
    @EnvironmentObject var networkController: NetBrain
    @State private var delayValue: Double = 3.0
    @State private var showSavedToast = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Policy fetch delay (seconds)")
                .font(.headline)

            HStack {
                Slider(value: $delayValue, in: 0...60, step: 0.1)
                Stepper(value: $delayValue, in: 0...600, step: 1) {
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
        .frame(minWidth: 420, minHeight: 180)
    }
}
#endif


@main
struct Man1fest0App: App {
    
//    #################################################################################
//    Order of classes is based on the order in which they were added
//    #################################################################################

    let photoController: PhotoViewModel
//    #################################################################################
//    Core data for persistent notes
//    #################################################################################
    private let coreDataStack = CoreDataStack(modelName: "NotesModel")
    @Environment(\.scenePhase) var scenePhase
    let pushController: PushBrain
    let extensionAttributeController: EaBrain
    let networkController: NetBrain
    let prestageController: PrestageBrain
    let xmlController: XmlBrain
    let progress: Progress
    let backgroundTasks: BackgroundTasks
#if os(macOS)
    let basher = Basher()
#endif
    let layout = Layout()
//    let jamfController: JamfController
    let scopingController: ScopingBrain
    let policyController: PolicyBrain
    let exportController: ImportExportBrain
    // State to control presentation of the Preferences sheet (macOS only)
    @State private var showingPreferences: Bool = false
    
    init() {
        self.photoController = PhotoViewModel()
        self.pushController = PushBrain()
        self.extensionAttributeController = EaBrain()
//        self.jamfController = JamfController()
        self.networkController = NetBrain()
        self.prestageController = PrestageBrain()
        self.xmlController = XmlBrain()
        self.progress = Progress()
//        self.basher = Basher()
        self.backgroundTasks = BackgroundTasks()
        self.scopingController = ScopingBrain()
        self.policyController = PolicyBrain()
        self.exportController = ImportExportBrain()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            
//                .environmentObject(photoController)
                .environmentObject(coreDataStack)
                .environment(\.managedObjectContext,
                             coreDataStack.managedObjectContext)
                .environmentObject(pushController)
                .environmentObject(extensionAttributeController)
                .environmentObject(networkController)
                .environmentObject(prestageController)
                .environmentObject(xmlController)
                .environmentObject(progress)
#if os(macOS)
                .environmentObject(basher)
#endif

                .environmentObject(layout)
                .environmentObject(backgroundTasks)
//                .environmentObject(jamfcontroller)
                .environmentObject(scopingController)
                .environmentObject(policyController)
                .environmentObject(exportController)
                // Present the preferences view as a sheet on macOS when requested from the menu
                #if os(macOS)
                .sheet(isPresented: $showingPreferences) {
                    AppPolicyDelayPreferencesView()
                        .environmentObject(networkController)
                }
                #endif
        }.commands {
            SidebarCommands() 
        }
        // Add a macOS-only menu command to open Preferences directly from the app menu
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    showingPreferences = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
        .onChange(of: scenePhase) { _ in
            coreDataStack.save()
        }
    }
}