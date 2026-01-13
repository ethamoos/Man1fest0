//
//  HTTPMethod.swift
<<<<<<< Updated upstream

=======
//  PackageTourist
//
//  Created by Alexis Bridoux on 24/04/2024.
//
>>>>>>> Stashed changes

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
