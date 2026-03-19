//
//  HTTPMethod.swift


import Foundation

// MARK: - HTTPMethod

struct HTTPMethod {

    let stringValue: String
}

// MARK: - Static

extension HTTPMethod {

    static let get = HTTPMethod(stringValue: "GET")
    static let post = HTTPMethod(stringValue: "POST")
}
