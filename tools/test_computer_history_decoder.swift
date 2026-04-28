import Foundation

func runTest(json: String, expectedUsername: String) -> Bool {
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    do {
        let wrapper = try decoder.decode(ComputerHistoryResponse.self, from: data)
        if let locs = wrapper.computerHistory.userLocation?.location, !locs.isEmpty {
            let first = locs[0]
            print("Decoded user location username: \(first.username ?? "<nil>") epoch: \(String(describing: first.dateTimeEpoch))")
            if let u = first.username, u == expectedUsername {
                return true
            } else {
                print("Unexpected username: \(String(describing: first.username)) expected: \(expectedUsername)")
                return false
            }
        } else {
            print("No user_location decoded")
            return false
        }
    } catch {
        print("Decoding error: \(error)")
        return false
    }
}

func runPolicyTest(json: String, expectedPolicyName: String, expectedPolicyID: String) -> Bool {
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    do {
        let wrapper = try decoder.decode(ComputerHistoryResponse.self, from: data)
        if let plogs = wrapper.computerHistory.policyLogs?.policyLog, !plogs.isEmpty {
            let first = plogs[0]
            print("Decoded policy log: name=\(first.policyName ?? "<nil>") id=\(first.policyID ?? "<nil>")")
            if let name = first.policyName, name == expectedPolicyName, let id = first.policyID, id == expectedPolicyID {
                return true
            } else {
                print("Unexpected policy entry: name=\(String(describing: first.policyName)) id=\(String(describing: first.policyID)) expected name=\(expectedPolicyName) id=\(expectedPolicyID)")
                return false
            }
        } else {
            print("No policy_logs decoded or array empty")
            return false
        }
    } catch {
        print("Decoding error: \(error)")
        return false
    }
}

let sample1 = """
{"computer_history":{"general":{"id":2,"name":"Macbook 15","udid":"dec4c97e-b630-4716-af45-75c8f4e15203","serial_number":"","mac_address":"FA:A0:22:3D:36:74"},"computer_usage_logs":[],"audits":[],"policy_logs":[],"commands":{"completed":[],"pending":[],"failed":[]},"user_location":[{"date_time":"2024/09/06 at 5:39 PM","date_time_epoch":1725644387121,"date_time_utc":"2024-09-06T17:39:47.121+0000","username":"Isabella Taylor","full_name":"","email_address":"","phone_number":"","department":"Development","building":"","room":"","position":""}],"mac_app_store_applications":{"installed":[],"pending":[],"failed":[]}}}
"""

let sample2 = """
{"computer_history":{"general":{"id":3,"name":"Loan - Macbook 02","udid":"278def96-a7d1-4da3-87ed-f68007a1ab83","serial_number":"","mac_address":""},"computer_usage_logs":[],"audits":[],"policy_logs":[],"commands":{"completed":[],"pending":[],"failed":[]},"user_location":[{"date_time":"2025/01/23 at 6:10 PM","date_time_epoch":1737655831054,"date_time_utc":"2025-01-23T18:10:31.054+0000","username":"Thomas Fradge Badger","full_name":"","email_address":"","phone_number":"","department":"Artificial Inteligence","building":"","room":"","position":""}],"mac_app_store_applications":{"installed":[],"pending":[],"failed":[]}}}
"""

let sample3 = """
{"computer_history":{"general":{"id":106,"name":"GreenDogCatalina","udid":"53177D6A-B9A1-5A34-8A81-899897251EAF","serial_number":"C02NG4E4G5RP","mac_address":"2C:F0:EE:2D:9A:CA"},"computer_usage_logs":[],"audits":[],"policy_logs":[{"policy_id":3,"policy_name":"MidiSport Driver","username":"amosdeane","date_completed":"2025/11/26 at 8:00 AM","date_completed_epoch":1764144007000,"date_completed_utc":"2025-11-26T08:00:07.000+0000","status":"Completed"}],"commands":{"completed":[],"pending":[],"failed":[]},"user_location":[],"mac_app_store_applications":{"installed":[],"pending":[],"failed":[]}}}
"""

@main
struct TestRunner {
    static func main() {
        var allOk = true
        print("Running ComputerHistory decoder tests...")
        allOk = allOk && runTest(json: sample1, expectedUsername: "Isabella Taylor")
        allOk = allOk && runTest(json: sample2, expectedUsername: "Thomas Fradge Badger")
        allOk = allOk && runPolicyTest(json: sample3, expectedPolicyName: "MidiSport Driver", expectedPolicyID: "3")

        if allOk {
            print("All tests passed")
            exit(EXIT_SUCCESS)
        } else {
            print("Some tests failed")
            exit(EXIT_FAILURE)
        }
    }
}
