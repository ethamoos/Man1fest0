
import Foundation


//  #######################################################################
//  Example Resource types
//  #######################################################################

//ResourceType.category
//ResourceType.computer
//ResourceType.computerBasic
//ResourceType.computerDetailed
//ResourceType.computerGroup
//ResourceType.configProfileMacOS
//ResourceType.configProfileDetailedMacOS
//ResourceType.department
//ResourceType.mobile
//ResourceType.account
//ResourceType.command
//ResourceType.package
//ResourceType.packages
//ResourceType.policy
//ResourceType.policies
//ResourceType.policyDetail
//ResourceType.script
//ResourceType.scripts
//


enum ResourceType {
    case building
    case buildingDetailed
    case category
    case categoryDetailed
    case computer
    case computerBasic
    case computerDetailed
    case computerExtensionAttribute
    case computerGroup
    case configProfileMacOS
    case configProfileDetailedMacOS
    case department
    case departmentDetailed
    case mobile
    case account
    case command
    case logflush
    case package
    case packages
    case policy
    case policies
    case policyDetail
    case script
    case scripts
}

func getURLFormat(data: ResourceType) -> String {
    print("Getting URL format")
    switch data {
    case .building:
        return "v1/buildings"
    case .buildingDetailed:
        return "v1/buildings"
    case .category:
        return "categories"
    case .categoryDetailed:
        return "v1/categories"
    case .computer:
        return "computers"
    case .computerBasic:
        return "computers/subset/basic"
    case .computerDetailed:
        return "computers/id/"
    case .computerGroup:
        return "/computergroups/id/"
    
    case .configProfileMacOS:
        return "osxconfigurationprofiles"
    
    case .configProfileDetailedMacOS:
        return "osxconfigurationprofiles/id/"
    case .department:
        return "departments"
    case .departmentDetailed:
        return "v1/departments"
    case .mobile:
        return "mobileDevices"
    case .account:
        return "accounts"
    case .command:
        return "mobiledevicecommands/command/"
    case .logflush:
        return "logflush/policy/id/"
    case .packages:
        return "packages"
    case .package:
        return "packages/id/"
    case .policy:
        return "policies"
    case .policies:
        return "policies/id/"
    case .policyDetail:
        return "/policies/id/"
    case .script:
//        return "/scripts/id/"
        return "/v1/scripts/"
    case .scripts:
        return "scripts"
    case .computerExtensionAttribute:
        return "/computerextensionattributes/id/"
    }
}

func getProcessFormat(data: ResourceType) -> String {
    print("Getting process format")
    switch data {
    case .building:
        return "process"
    case .buildingDetailed:
        return "process"
    case .category:
        return "process"
    case .categoryDetailed:
        return "process"
    case .computer:
        return "process"
    case .computerDetailed:
        return "process"
    case .computerGroup:
        return "process"
    case .configProfileMacOS:
        return "process"
    case .configProfileDetailedMacOS:
        return "process"
    case .department:
        return "process"
    case .departmentDetailed:
        return "process"
    case .computerBasic:
        return "process"
    case .mobile:
        return "process"
    case .account:
        return "process"
    case .command:
        return "process"
    case .logflush:
        return "logflush"
    case .package:
        return "process"
    case .packages:
        return "process"
        
    case .policy:
        return "process"
    case .policies:
        return "policies"
        
    case .policyDetail:
        return "processDetail"
    case .scripts:
        return "process"
    case .script:
        return "processDetail"
    case .computerExtensionAttribute:
        return "process"
    }
}



func getReplyString(data: ResourceType) -> String {
    print("Getting reply format")
    switch data {
    case .building:
        return "BuildingReply"
    case .buildingDetailed:
        return "BuildingReply"
    case .category:
        return "CategoriesReply"
    case .categoryDetailed:
        return "CategoriesReply"
    case .computer:
        return "ComputersReply"
    case .computerDetailed:
        return "ComputerDetailedReply"
    case .computerGroup:
        return "process"
    case .configProfileMacOS:
        return "process"
    case .configProfileDetailedMacOS:
        return "process"
    case .department:
        return "DepartmentsReply"
    case .departmentDetailed:
        return "DepartmentsReply"
    case .computerBasic:
        return "ComputersBasicReply"
    case .mobile:
        return "MobileDevicesReply"
    case .account:
        return "AccountsReply"
    case .command:
        return "CommandReply"
    case .logflush:
        return "LogflushReply"
    case .package:
        return "PackageReply"
    case .packages:
        return "PackagesReply"
    case .policy:
        return "PolicyReply"
    case .policies:
        return "PoliciesReply"
    case .policyDetail:
        return "PolicyDetailReply"
    case .script:
        return "ScriptReply"
    case .scripts:
        return "ScriptsReply"
    case .computerExtensionAttribute:
        return "ComputerExtensionAttributeReply"
    }
}


//func getReplyType(data: ResourceType) -> Any {
//    switch data {
//    case .computer:
//        return ComputersReply
//    case .mobile:
//        return MobileDevicesReply
//    case .account:
//        return AccountsReply
//    case .command:
//        return CommandReply
//    case .policy:
//        return PolicyReply
//    case .policyDetail:
//        return PolicyDetailReply
//
//    }
//}


func getSingleInstanceString(data: ResourceType) -> String {
    print("Getting single instance format")
    switch data {
    case .building:
        return "BuildingReply"
    case .buildingDetailed:
        return "BuildingReply"
    case .category:
        return "Category"
        case .categoryDetailed:
        return "Category"
    case .computer:
        return "Computer"
    case .computerDetailed:
        return "ComputerDetailed"
    case .computerGroup:
        return "ComputerGroup"
    case .configProfileMacOS:
        return "ConfigProfile"
    case .configProfileDetailedMacOS:
        return "ConfigProfileDetailedMacOS"
    case .department:
        return "Department"
    case .departmentDetailed:
        return "Department"
    case .computerBasic:
        return "ComputerBasic"
    case .mobile:
        return "Device"
    case .account:
        return "Account"
    case .command:
        return "Command"
    case .policy:
        return "Policy"
    case .policies:
        return "Policies"
        
    case .logflush:
        return "Logflush"
        
    case .package:
        return "Package"
    case .packages:
        return "Packages"
    case .policyDetail:
        return "PolicyDetail"
    case .script:
        return "Script"
    case .scripts:
        return "Scripts"
    case .computerExtensionAttribute:
        return "ComputerExtensionAttribute"
    }
}

func getViewString(data: ResourceType) -> String {
    print("Getting view string format")
    switch data {
    case .building:
        return "BuildingView"
    case .buildingDetailed:
        return "BuildingView"
    case .category:
        return "CategoriesView"
    case .categoryDetailed:
        return "CategoriesView"
    
    case .computer:
        return "ComputersView"
    case .computerDetailed:
        return "ComputerDetailedView"
    case .computerBasic:
        return "ComputersBasicView"    
    case .computerGroup:
        return "ComputerGroupView"
    case .configProfileMacOS:
        return "ConfigProfileViewMacOS"
    case .configProfileDetailedMacOS:
        return "ConfigProfileDetailedMacOS"
    case .department:
        return "DepartmentsView"
    case .departmentDetailed:
        return "DepartmentsView"
    case .mobile:
        return "MobileDevicesView"
    case .account:
        return "AccountsView"
    case .command:
        return "CommandView"
        
        
    case .logflush:
        return "LogflusheView"
        
    case .package:
        return "PackageView"
    case .packages:
        return "PackagesView"
    case .policy:
        return "PolicyView"
    case .policies:
        return "PoliciesView"
    case .policyDetail:
        return "PolicyDetailView"
    case .script:
        return "ScriptDetailView"
    case .scripts:
        return "ScriptsView"
    case .computerExtensionAttribute:
        return "ComputerEAView"
    }
}

func getReceivedString(data: ResourceType) -> String {
    print("Getting received format")
    switch data {
    case .building:
        return "receivedBuilding"
    case .buildingDetailed:
        return "receivedBuildings"
    case .category:
        return "receivedCategories"
    case .categoryDetailed:
        return "receivedCategories"
    case .computer:
        return "receivedComputers"
    case .computerDetailed:
        return "ComputerDetailedView"    
    case .computerGroup:
        return "ComputerGroupView"
    case .configProfileMacOS:
        return "ConfigProfileDetailedViewMacOS"
    case .configProfileDetailedMacOS:
        return "ConfigProfileDetailedMacOS"
    case .department:
        return "receivedDepartments"
    case .departmentDetailed:
        return "Department"
    case .computerBasic:
        return "receivedComputersBasic"
    case .mobile:
        return "receivedMobileDevices"
    case .account:
        return "receivedAccounts"
    case .command:
        return "receivedCommands"
    case .logflush:
        return "receivedLogflush"
    case .packages:
        return "receivedPackages"
    case .package:
        return "receivedPackage"
    case .policy:
        return "receivedPolicies"
    case .policies:
        return "receivedPolicies"
    case .policyDetail:
        return "receivedPolicyDetails"
    case .script:
        return "receivedScriptDetails"
    case .scripts:
        return "receivedScripts"
    case .computerExtensionAttribute:
        return "receivedComputerEAs"
    }
}



