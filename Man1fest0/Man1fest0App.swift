
import SwiftUI


@main
struct Man1fest0App: App {
    
//    Order of classes is based on the order in which they were added
    
    
//    Core data for persistent notes
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
    
    init() {
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
//                .environmentObject(jamfController)
                .environmentObject(scopingController)
                .environmentObject(policyController)
                .environmentObject(exportController)
        }.commands {
            SidebarCommands() // 1
        }
        .onChange(of: scenePhase) { _ in
            coreDataStack.save()
        }
    }
}
