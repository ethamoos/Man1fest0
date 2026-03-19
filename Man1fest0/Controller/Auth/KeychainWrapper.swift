/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

struct KeychainWrapperError: Error {
  var message: String?
  var type: KeychainErrorType

  enum KeychainErrorType {
    case badData
    case servicesError
    case itemNotFound
    case unableToConvertToString
  }

  init(status: OSStatus, type: KeychainErrorType) {
    self.type = type
    if let errorMessage = SecCopyErrorMessageString(status, nil) {
      self.message = String(errorMessage)
    } else {
      self.message = "Status Code: \(status)"
    }
  }

  init(type: KeychainErrorType) {
    self.type = type
  }

  init(message: String, type: KeychainErrorType) {
    self.message = message
    self.type = type
  }
}

class KeychainWrapper {
    
  func storeGenericPasswordFor(
    account: String,
    service: String,
    password: String
    
  ) throws {
    if password.isEmpty {
      try deleteGenericPasswordFor(account: account, service: service)
      return
    }
    guard let passwordData = password.data(using: .utf8) else {
      print("Error converting value to data.")
      throw KeychainWrapperError(type: .badData)
    }

    // 1
    let query: [String: Any] = [
      // 2
      kSecClass as String: kSecClassGenericPassword,
      // 3
      kSecAttrAccount as String: account,
      // 4
      kSecAttrService as String: service,
      // 5
      kSecValueData as String: passwordData
    ]

    // 1
    let status = SecItemAdd(query as CFDictionary, nil)
    switch status {
    // 2
    case errSecSuccess:
      break
    case errSecDuplicateItem:
      try updateGenericPasswordFor(
        account: account,
        service: service,
        password: password)
    // 3
    default:
      throw KeychainWrapperError(status: status, type: .servicesError)
    }
  }

  func getGenericPasswordFor(account: String, service: String) throws -> String {
    let query: [String: Any] = [
      // 1
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service,
      // 2
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnAttributes as String: true,
      // 3
      kSecReturnData as String: true
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status != errSecItemNotFound else {
      throw KeychainWrapperError(type: .itemNotFound)
    }
    guard status == errSecSuccess else {
      throw KeychainWrapperError(status: status, type: .servicesError)
    }

    guard let existingItem = item as? [String: Any],
      // 2
      let valueData = existingItem[kSecValueData as String] as? Data,
      // 3
      let value = String(data: valueData, encoding: .utf8)
      else {
        // 4
        throw KeychainWrapperError(type: .unableToConvertToString)
    }

    //5
    return value
  }

  func updateGenericPasswordFor(
    account: String,
    service: String,
    password: String
  ) throws {
    guard let passwordData = password.data(using: .utf8) else {
      print("Error converting value to data.")
      return
    }
    // 1
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service
    ]

    // 2
    let attributes: [String: Any] = [
      kSecValueData as String: passwordData
    ]

    // 3
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    guard status != errSecItemNotFound else {
      throw KeychainWrapperError(message: "Matching Item Not Found", type: .itemNotFound)
    }
    guard status == errSecSuccess else {
      throw KeychainWrapperError(status: status, type: .servicesError)
    }
  }

  func deleteGenericPasswordFor(account: String, service: String) throws {
    // 1
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account,
      kSecAttrService as String: service
    ]

    // 2
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainWrapperError(status: status, type: .servicesError)
    }
  }
}
