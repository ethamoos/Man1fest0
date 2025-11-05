//
//  JamfObject.swift
//  jamf_list
//
//  From SwiftAPITutorial by Armin Briegel
//  https://github.com/scriptingosx/SwiftAPITutorial

import Foundation

protocol JamfObject: Codable, Identifiable {
    var id: String { get set }
    
    static var getAllEndpoint: String { get }
    
    /** Build the URL for the request to fetch all objects */
    static func getAllURLComponents(server: String) throws -> URLComponents
    
    /** Gets a list of all objects from the Jamf Pro Server */
    static func getAll(server: String, auth: JamfAuthToken) async throws -> [Self]
}

extension JamfObject {
    
    func separationLine() {
        print("------------------------------------------------------------------")
    }
    /** build the URL for the request to fetch all categories */
    static func getAllURLComponents(server: String) throws -> URLComponents {
        // assemble the URL for the Jamf API
        //      print("Running getAllURLComponents for server:\(server)")
        
        guard var components = URLComponents(string: server)
        else {
            throw JamfAPIError.badURL
        }
        components.path = self.getAllEndpoint
        print("Components are:\(components)")
        
        return components
    }
    
    /** Gets a list of all categories from the Jamf Pro Server */
    static func getAll(server: String, auth: JamfAuthToken) async throws -> [Self] {
        // MARK: Prepare Request
        print("------------------------------------------------------------------")
        print("Running getAll for server:\(server)")
        let components = try getAllURLComponents(server: server)
        
        guard let url = components.url
        else {
            throw JamfAPIError.badURL
        }
        
        // print("Request URL: \(url.absoluteString)")
        
        // MARK: Send Request and get Data
        // create the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer " + auth.token, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        // send request and get data
        guard let (data, response) = try? await URLSession.shared.data(for: request)
        else {
            throw JamfAPIError.requestFailed
        }
        
        // MARK: Handle Errorw
        // check the response code
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        if statusCode != 200 {
            // error getting token
            throw JamfAPIError.http(statusCode)
        }
        
//        Returned JSON or XML
//        print(String(data: data, encoding: .utf8) ?? "no data")
        
        // MARK: Parse JSON Data
        let decoder = JSONDecoder()
        
        // set date decoding to match Jamf's date format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        do {
            let result = try decoder.decode(JamfResults<Self>.self, from: data)
            print("------------------------------------------------------------------")
            print("Url of request is:\(url)")
            return result.results
            
            // handle decoding errors - handle errors
            // see DecodingError documentation for details
        } catch let DecodingError.dataCorrupted(context) {
            print("------------------------------------------------------------------")
            print("\(context.codingPath): data corrupted: \(context.debugDescription)")
            //      print(result.results)
            
        } catch let DecodingError.keyNotFound(key, context) {
            print("\(context.codingPath): key \(key) not found: \(context.debugDescription)")
        } catch let DecodingError.valueNotFound(value, context) {
            print("\(context.codingPath): value \(value) not found: \(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("\(context.codingPath): type \(type) mismatch: \(context.debugDescription)")
        } catch {
            print("error: ", error)
        }
        
        throw JamfAPIError.decode
    }
    
}

struct JamfResults<T: JamfObject>: Codable {
    var totalCount: Int
    var results: [T]
}


//struct JamfBuildingResults<T: JamfObject>: Codable {
//    var size: Int
//    var buildings: [T]
//}
