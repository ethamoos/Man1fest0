// Retired JamfObjects sample — excluded from compilation
#if false
import Foundation

struct ComputerSample: JamfObject {
  
    var id: String
    var general: General
    var hardware: Hardware
    var operatingSystem: OperatingSystem
    
  struct General: Codable {
    var name: String
    var assetTag: String?
    var lastEnrolledDate: Date
    var userApprovedMdm: Bool
  }
  
  struct Hardware: Codable {
    var model: String
    var modelIdentifier: String
    var serialNumber: String
    var appleSilicon: Bool
  }
  
  struct OperatingSystem: Codable {
    var name: String
    var version: String
    var build: String
  }
  
  static let getAllEndpoint = "/api/v1/computers-inventory"
  
  static func getAllURLComponents(server: String) throws -> URLComponents {
    guard var components = URLComponents(string: server)
    else {
      throw JamfAPIError.badURL
    }
    components.path = self.getAllEndpoint
    components.queryItems = [ URLQueryItem(name: "section", value: "GENERAL"),
                              URLQueryItem(name: "section", value: "HARDWARE"),
                              URLQueryItem(name: "section", value: "OPERATING_SYSTEM"),
                              URLQueryItem(name: "sort", value: "id:asc") ]
    return components
  }
}

extension ComputerSample {
    
  static var samples = [
    ComputerSample.sampleMacBookPro,
    ComputerSample.sampleMacBookAir,
    ComputerSample.sampleMacmini,
    ComputerSample.sampleIMac,
    ComputerSample.sampleMacStudio,
    ComputerSample.sampleMacProGen1,
    ComputerSample.sampleMacProGen2,
    ComputerSample.sampleMacProGen3
  ]
  
  static var sampleMacBookPro: ComputerSample {
    let general = General(
      name: "MacBook Pro",
      lastEnrolledDate: Date.init(timeIntervalSinceNow: -86400.0),
      userApprovedMdm: true
    )
    let hardware = Hardware(
      model: "MacBook Pro",
      modelIdentifier: "MacBookPro1,1",
      serialNumber: "SAMPLE111111",
      appleSilicon: false
    )
    let operatingSystem = OperatingSystem(
      name: "macOS",
      version: "13.0",
      build: "22A100"
    )
    let sample = ComputerSample(
      id: "999991",
      general: general,
      hardware: hardware,
      operatingSystem: operatingSystem
    )
    return sample
  }

  // ... additional samples omitted for brevity
}
#endif
