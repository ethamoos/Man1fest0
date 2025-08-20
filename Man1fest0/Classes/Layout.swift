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
        GridItem(.fixed(200), alignment: .leading)
    ]
    
    let columns = [
        GridItem(.fixed(200), alignment: .leading), // <------ HERE!
        GridItem(.flexible(minimum: 50, maximum: .infinity), alignment: .leading)
    ]
    let threeColumns = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ]
    
    let fourColumns = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200)),
        GridItem(.fixed(250)),
        GridItem(.flexible()),
    ]
    
    let fiveColumns = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200)),
        GridItem(.fixed(250)),
        GridItem(.fixed(200)),
        GridItem(.flexible()),
    ] 
    
    let columnAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading)
    ]
    
    let columnsAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading),
        GridItem(.adaptive(minimum: 250))
    ]
    
    let threeColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading),
        GridItem(.adaptive(minimum: 250)),
        GridItem(.adaptive(minimum: 250))
    ]
    let fourColumnsAdaptive = [
        GridItem(.adaptive(minimum: 250), alignment: .leading),
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
        GridItem(.flexible(minimum: 20), alignment: .leading),
    ]
      
    let columnsFlexNarrow = [
        GridItem(.flexible(minimum: 20), alignment: .leading),
    ]
    let threeColumnsFlexNarrow = [
        GridItem(.flexible(minimum: 20), alignment: .leading),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100))
    ]
    
      let fourColumnsFlexNarrow = [
        GridItem(.flexible(minimum: 20), alignment: .leading),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100)),
        GridItem(.flexible(minimum: 100))
    ]
    
    let columnFlex = [
        GridItem(.flexible(minimum: 250))
    ]
    
    let columnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible(minimum: 250))
    ]
    
    let threeColumnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let fourColumnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let fiveColumnsFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    
    let columnsAllFlex = [
        GridItem(.flexible(), alignment: .leading),
        GridItem(.flexible())
    ]
    
    let columnsFlexAdaptive = [
        GridItem(.adaptive(minimum: 300), alignment: .leading),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnsFlexMedium = [
        GridItem(.fixed(600), alignment: .leading),
        GridItem(.flexible(minimum: 600))
    ]
    
    let threeColumnsFlexMedium = [
        GridItem(.fixed(600), alignment: .leading),
        GridItem(.fixed(600)),
        GridItem(.flexible(minimum: 600))
    ]
    
    let columnsFlexAdaptiveMedium = [
        GridItem(.adaptive(minimum: 150), alignment: .leading),
        GridItem(.adaptive(minimum: 150))
    ]
    
    let columnFlexMedium = [
        GridItem(.adaptive(minimum: 150), alignment: .leading),
    ]
    
    let columnFlexWide = [
        GridItem(.adaptive(minimum: 400), alignment: .leading),
    ]
    
    let columnsFlexWide = [
        GridItem(.flexible(minimum: 300), alignment: .leading),
        GridItem(.flexible(minimum: 300))
    ]
    
    let columnWide = [
        GridItem(.fixed(400), alignment: .leading),
    ]
    
    let columnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.fixed(400))
    ]
    
    let threeColumnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.fixed(400)),
        GridItem(.fixed(400))
    ]
    
    let fourColumnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let fiveColumnsWide = [
        GridItem(.fixed(400), alignment: .leading),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300)),
        GridItem(.adaptive(minimum: 300))
    ]
    
    let columnFixed = [
        GridItem(.fixed(200), alignment: .leading),
    ]
    let columnsFixed = [
        GridItem(.fixed(200), alignment: .leading),
        GridItem(.fixed(200), alignment: .leading)
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
