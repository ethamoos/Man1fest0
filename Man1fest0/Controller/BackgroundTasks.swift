//
//  BackgroundTasks.swift
//  Man1fest0
//
//  Created by Amos Deane on 24/04/2024.
//

import Foundation




class BackgroundTasks: ObservableObject {
    
    var assignedPackages: [Package] = []
//    var packagesFound: [Package]? = []
    var assignedPackagesByNameDict: [String: String] = [:]
    var assignedPackagesByNameSet = Set<String>()
    var allPackagesByNameDict: [String: String] = [:]
    
    
    
    
    var clippedPackages = Set<String>()
    var unassignedPackagesSet = Set<String>()
    var unassignedPackagesArray: [String] = []
    var unassignedPackagesByNameDict: [String: String] = [:]
    
    
    
    var allPackagesByNameSet = Set<String>()
    
    //  ########################################
    //  getPackagesInUse
    //  ########################################
    
    
    func getPackagesInUse (allPoliciesDetailedArray: [PolicyDetailed?] ) {
        
        print(self.separationLine())
        print("Running: getPackagesInUse")

//        DEBUG
//        print("PolicyDetailed is: \(String(describing: allPoliciesDetailedArray))")

        
        print("allPoliciesDetailed initial count is:\(allPoliciesDetailedArray.count)")

//        let allPoliciesDetailed = networkController.allPoliciesDetailed
//        
//        for eachPolicy in allPoliciesDetailed {
////            print("Policy is:\(String(describing: eachPolicy))")
//            
//            let scriptsFound: [PolicyScripts]? = eachPolicy?.scripts
//                        
//            for script in scriptsFound ?? [] {
//                print("Script is:\(script)")
//
//                //        ########################################
//                //                Convert to dict
//                //        ########################################
//                
//                assignedScriptsByNameDict[script.name ?? "" ] = String(describing: script.jamfId)
//                assignedScripts.insert(script, at: 0)
        
        //        ########################################
        //        All Scripts - convert to set
        //        ########################################
        
//        //        All scripts in Jamf converted to a set
//        allScriptsByNameSet = Set(Array(allScriptsByNameDict.keys))
//        //        ########################################
//        //        Assigned Scripts
//        //        ########################################
//        //        All scripts found in policies
//        assignedScriptsByNameSet = Set(Array(assignedScriptsByNameDict.keys))//
//        //        ########################################
//        //        Unassigned scripts
//        //        ########################################
//        
//        print("everything not in both - scripts not in use")
//        unassignedScriptsSet = allScriptsByNameSet.symmetricDifference(assignedScriptsByNameSet)
//        print(unassignedScriptsSet.count)
//        
//        print("unassignedScriptsArray")
//        unassignedScriptsArray = Array(unassignedScriptsSet)
//        print(unassignedScriptsArray.count)
//        
//        
        
        
        
        for eachPolicy in allPoliciesDetailedArray {
                        
            print("Policy is:\(String(describing: eachPolicy?.general?.name ?? ""))")
            
            let packagesFound = eachPolicy?.package_configuration?.packages
            
            for package in packagesFound ?? [] {
                print("#### Adding package found:\(String(describing: package.name))")
                

                //        ########################################
                //                Convert to dict and add
                //        ########################################
                
                assignedPackagesByNameDict[package.name ] = String(describing: package.jamfId)
                assignedPackages.insert(package, at: 0)
            }
        }
        print("assignedPackagesByNameDict final value is:\(assignedPackagesByNameDict.count)")
        
        
        
        //        ########################################
        //        DEBUG - assignedPackagesByNameDict
        //        ########################################

//        print(self.separationLine())
//        print("Total assignedPackagesByNameDict")
//        print(assignedPackagesByNameDict.count)
//        print("assignedPackagesByNameDict is:")
//        print(assignedPackagesByNameDict)
//        - prints a lot of data to the console
        
        
        //        ########################################
        //        SET Assigned Packages
        //        ########################################
        
        //        ########################################
        //        All packages found in policies
        //        ########################################
        print("Convert assigned packages to a set")
        assignedPackagesByNameSet = Set(Array(assignedPackagesByNameDict.keys))
        
        

//        return assignedPackagesByNameDict
    }
    
    
    
    
    
    
    func getPackagesNotInUse (allPoliciesDetailedArray: [PolicyDetailed?] , allPackages: [Package]) {
        
        //        ########################################
        //                Convert all packages to dict
        //        ########################################
        
        //  var allPackagesByNameDict: [String: String] = [:]
        
        print("Running: getPackagesNotInUse")
        
        //        ########################################
        //                Convert all packages to dict
        //        ########################################
        
        
        
        for package in allPackages {
            print("Package is:\(package) - add to allPackagesByNameDict")
            
            //        ########################################
            //                Convert allPackages to a dict
            //        ########################################
            
            allPackagesByNameDict[package.name ] = String(describing: package.jamfId)
        }
        
        //        ########################################
        //        DEBUG - allPackagesByNameDict
        //        ########################################
        
        print(self.separationLine())
        print("allPackages now converted to a dict")
        print("Total allPackagesByNameDict")
        print(allPackagesByNameDict.count)
        
        //        print("allPackagesByNameDict is:")
        //        print(allPackagesByNameDict)
        //        - prints a lot of data to the console
        
        //        ########################################
        //        All packages in Jamf converted to a set
        //        ########################################
        
        allPackagesByNameSet = Set(Array(allPackagesByNameDict.keys))
        
        print(self.separationLine())
        print("Confirming how many packages are not in use")
        print("everything not in both - packages not in use as a set")
        unassignedPackagesSet = allPackagesByNameSet.symmetricDifference(assignedPackagesByNameSet)
        
        //        ########################################
        //        DEBUG
        //        print(unassignedPackagesSet)
        //        ########################################
        
        print("Total unnasigned packages is:")
        print(unassignedPackagesSet.count)
        
        //        ########################################
        //        Convert unassigned packages to array
        //        ########################################
        
        print(self.separationLine())
        print("Total unassignedPackagesArray is:")
        unassignedPackagesArray = Array(unassignedPackagesSet)
        print(unassignedPackagesArray.count)
        
//        ########################################
//        DEBUG
//        print("All unassignedPackagesArray are:")
//        print(unassignedPackagesArray)
//        ########################################

    }
    
    
        
        func findDifference() -> [String : String] {
        
            //        ########################################
            //        Now go through list of all packages and check if each package occurs in the list of assigned packages.
            //        If it does, remove it so that eventually a list remains that contains only unused packages.
            //        ########################################

        let assigned = assignedPackagesByNameDict
        var allPackages = allPackagesByNameDict
        
        for (item,value) in assigned {
            print(self.separationLine())
            print("Processing assigned items:\(item) = \(value)")
            let assignedItem = (item)
            print("Assigned item is:\(assignedItem)")
            
            for (item, _) in allPackages {
                let currentItem = (item)
                print(self.separationLine())
                print("Processing all packages")
//                print("Current value pair is:\(item) = \(value)")
//                print("Current item is:\(currentItem)")
                if currentItem == assignedItem {
                    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
                    print("Match found for \(currentItem)")
                    print("Removing a key-Value pair")
                    allPackages.removeValue(forKey: currentItem)
                } else {
                    print("No match found for:\(currentItem)")
                }
            }
        }
        
        print("--------------------------------------------")
        print("unusedPackages are:")
        unassignedPackagesByNameDict = allPackages
        print(unassignedPackagesByNameDict)
        print("Return unusedPackages")
        return unassignedPackagesByNameDict
    }
    
    
//    func getValues(allPackages: [Package]) async {
//        
//        //        ########################################
//        //                Convert all packages to dict
//        //        ########################################
//        
//  var allPackagesByNameDict: [String: String] = [:]
//
//        print("Running: getValues")
//
//        for package in allPackages {
//            print("Package is:\(package) - add to allPackagesByNameDict")
//            assignedPackages.append(package)
//            
//            //        ########################################
//            //                Convert to dict
//            //        ########################################
//            
//            allPackagesByNameDict[package.name ] = String(describing: package.jamfId)
//            
//        }
//                
//        print(self.separationLine())
//        print("allPackagesByNameDict is:")
//        print(allPackagesByNameDict)
//
//        print(self.separationLine())
//        print("assignedPackagesByNameDict is:")
//        print(assignedPackagesByNameDict)
//        
//        
//        //        ########################################
//        //        All Packages - convert to set
//        //        ########################################
//        
//        //        All packages in Jamf converted to a set
//        allPackagesByNameSet = Set(Array(allPackagesByNameDict.keys))
//        
//        //        ########################################
//        //        SET Assigned Packages
//        //        ########################################
//        
//        //        All packages found in policies
//        assignedPackagesByNameSet = Set(Array(assignedPackagesByNameDict.keys))
//        
//    
//        //        ########################################
//        //        Unassigned packages
//        //        ########################################
//   
//        print(self.separationLine())
//        print("everything not in both - packages not in use as a set")
//        unassignedPackagesSet = allPackagesByNameSet.symmetricDifference(assignedPackagesByNameSet)
//        print(unassignedPackagesSet)
//        print(unassignedPackagesSet.count)
//        
//        print(self.separationLine())
//        print("unassignedPackagesArray")
//        unassignedPackagesArray = Array(unassignedPackagesSet)
//        print(unassignedPackagesArray.count)
//   
//        let assigned = assignedPackagesByNameDict
//        var allPackages = allPackagesByNameDict
//        
//        for (item,value) in assigned {
//            
//            print("--------------------------------------------")
//            print("############################################")
//            print("Processing assigned items:\(item) = \(value)")
//            
//            let assignedItem = (item)
//            
//            print("Assigned item is:\(assignedItem)")
//            
//            for (item, value) in allPackages {
//                
//                let currentItem = (item)
//                print("--------------------------------------------")
//                print("Processing all packages")
//                print("Current value pair is:\(item) = \(value)")
//                print("Current item is:\(currentItem)")
//                if currentItem == assignedItem {
//                    print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
//                    print("Match found for \(currentItem)")
//                    print("Removing a key-Value pair")
//                    allPackages.removeValue(forKey: currentItem)
//                } else {
//                    print("No match found for:\(currentItem)")
//                }
//            }
//        }
//        
//        print("--------------------------------------------")
//        print("unusedPackages are:")
//        unassignedPackagesByNameDict = allPackages
//        print(unassignedPackagesByNameDict)
////      
//        
//        //        ########################################
//        //        SET Unassigned packages
//        //        ########################################
//        
////
////        print(self.separationLine())
////        print("One set minus the contents of another - packages not in use")
////        clippedPackages = allPackagesByNameSet.subtracting(assignedPackagesByNameSet)
////        print(clippedPackages)
////        print(clippedPackages.count)
//        
//    }
    
    func separationLine() {
        print("------------------------------------------------------------------")
    }
}
