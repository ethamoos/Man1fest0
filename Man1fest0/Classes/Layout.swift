//
//  Layout.swift
//  Man1fest0
//
//  Created by Amos Deane on 23/04/2024.
//

import Foundation
import SwiftUI


class Layout: ObservableObject {
    
    @EnvironmentObject var networkController: NetBrain
    
    let date = String(DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .short))

   
    
    
    let column = [
        GridItem(.fixed(200))
    ]
    
    let columns = [
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    let threeColumns = [
        GridItem(.fixed(200)),
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    
    let fourColumns = [
        GridItem(.fixed(200)),
        GridItem(.fixed(200)),
        GridItem(.fixed(250)),
        GridItem(.flexible()),
    ]
    
    let fiveColumns = [
        GridItem(.fixed(200)),
        GridItem(.fixed(200)),
        GridItem(.fixed(250)),
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ] 
    
    let columnAdaptive = [
        GridItem(.adaptive(minimum: 250))
    ]
    
    let columnsAdaptive = [
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250))
    ]
    
    let threeColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250))
    ]
    let fourColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250))
    ]
   
    let fiveColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250)),
    ]
    
    let fiveColumnsAdaptiveWide = [
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnFlexNarrow = [
        GridItem(.adaptive(minimum: 100))
    ]
      
    let columnsFlexNarrow = [
        GridItem(.adaptive(minimum: 100))
    ]
    let threeColumnsFlexNarrow = [
        GridItem(.flexible(minimum: 20)),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100))
    ]
    
      let fourColumnsFlexNarrow = [
        GridItem(.flexible(minimum: 20)),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100))
    ]
    
    let columnFlex = [
        GridItem(.flexible(minimum: 250))
    ]
    
    let columnsFlex = [
        GridItem(.flexible(minimum: 250)),
        GridItem(.flexible(minimum: 250))
    ]
    
    let threeColumnsFlex = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let fourColumnsFlex = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let fiveColumnsFlex = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let columnsFlexWide = [
        GridItem(.flexible(minimum: 300)),
        GridItem(.flexible(minimum: 300))
    ]
    
    let columnsAllFlex = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let columnsFlexAdaptive = [
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnsFlexMedium = [
        GridItem(.fixed(600)),
        GridItem(.flexible(minimum: 600))
    ]
    
    let threeColumnsFlexMedium = [
        GridItem(.fixed(600)),
        GridItem(.fixed(600)),
        GridItem(.flexible(minimum: 600))
    ]
    
    let columnsFlexAdaptiveMedium = [
        GridItem(.adaptive(minimum: 150)),
        GridItem(.adaptive(minimum: 150))
    ]
    
    let columnFlexMedium = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    let columnFlexWide = [
        GridItem(.adaptive(minimum: 400))
    ]
    
    let columnWide = [
        GridItem(.fixed(400))
    ]
    
    let columnsWide = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    let threeColumnsWide = [
        GridItem(.fixed(400)),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    let fourColumnsWide = [
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let fiveColumnsWide = [
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnFixed = [
        GridItem(.fixed(200))
    ]  
    let columnsFixed = [
        GridItem(.fixed(200)),
        GridItem(.fixed(200))
    ]
    
    
    func separationLine() {
        print("------------------------------------------------")
    }
    
    func doubleSeparationLine() {
        print("================================================")
    }
    
    func asteriskSeparationLine() {
        print("************************************************")
    }
    
    func atSeparationLine() {
        print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    }
    
}
