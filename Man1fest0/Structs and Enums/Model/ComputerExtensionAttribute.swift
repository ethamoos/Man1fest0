//
//  ComputerExtensionAttribute.swift
//  Man1fest0
//
//  Created by Amos Deane on 05/02/2025.
//



//    #################################################################################
//    ############ Computer Extension Attributes
//    #################################################################################

// MARK: - ComputerExtensionAttributes

// ##################################
// UNUSED - Struct
// ##################################
struct ComputerExtensionAttributesDetailed: Codable {
    
    let prefill, form, defaultValue, name: String
    let id, priority: Int
    
}

struct ComputerExtensionAttributes: Codable {
    let computerExtensionAttributes: [ComputerExtensionAttribute]

    enum CodingKeys: String, CodingKey {
        case computerExtensionAttributes = "computer_extension_attributes"
    }
}

// MARK: - ComputerExtensionAttribute
struct ComputerExtensionAttribute: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let enabled: Bool
}


struct ComputerExtensionAttributeDetailedResponse: Codable {
    let computerExtensionAttribute: ComputerExtensionAttributeDetailed

    enum CodingKeys: String, CodingKey {
        case computerExtensionAttribute = "computer_extension_attribute"
    }
}

// MARK: - ComputerExtensionAttribute
struct ComputerExtensionAttributeDetailed: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let enabled: Bool
    let description, dataType: String
    let inputType: InputType
    let inventoryDisplay: String

    enum CodingKeys: String, CodingKey {
        case id, name, enabled, description
        case dataType = "data_type"
        case inputType = "input_type"
        case inventoryDisplay = "inventory_display"
    }
}

// MARK: - InputType
struct InputType: Codable, Equatable {
    let type: String
    let platform: String
    let script: String
}
