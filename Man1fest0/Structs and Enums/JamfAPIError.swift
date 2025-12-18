//
//  JamfAPIError.swift
//
//  Adapted from SwiftAPITutorial by Armin Briegel
//  https://github.com/scriptingosx/SwiftAPITutorial

import Foundation


enum JamfAPIError: Error {
    case requestFailed
    case http(Int)
    case authentication
    case forbidden
    case badRequest
    case decode
    case encode
    case badURL
    case conflict
    case noCredentials
    case badResponseCode
    case couldntEncodeNamePass
    case unknown
}


// ##################################
// UNUSED
// ##################################
func getErrorDescription(data: JamfAPIError, code: Int) -> String {
    print("Getting Error Description")
    switch data {
    case .requestFailed:
        return "v1/buildings"
    case .http:
        return "categories"
    case .authentication:
        return "v1/categories"
    case .badRequest:
        return "v1/categories"
    case .conflict:
        return "v1/categories"
    case .decode:
        return "computers"
    case .encode:
        return "computers/subset/basic"
    case .forbidden:
        return "computers/subset/basic"
    case .badURL:
        return "computers/id/"
    case .noCredentials:
        return "/computergroups/id/"
    case .badResponseCode:
        return "osxconfigurationprofiles"
    case .unknown:
        return "unknown"
    case .couldntEncodeNamePass:
        return ""    }
}
