import SwiftUI

// ##################################
// UNUSED - Struct
// ##################################
struct ComputerBasicView: View {
    
    var selectedResourceType: ResourceType
    @State var server: String
    @State var user: String
    @State var password: String
    @State var computers: [Computer] = []
    @State var selection: [Computer] = []
    
    @EnvironmentObject var networkController: NetBrain
    
    @State var currentDetailedPolicy: PolicyCodable? = nil
    
    var body: some View {
        Text("Computers Basic")
    }
}





//}

//struct TestView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestView()
//    }
//}
