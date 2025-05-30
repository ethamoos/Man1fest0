//
//  PushBrain.swift
//  Man1fest0
//
//  Created by Amos Deane on 04/09/2024.
//

import Foundation
import SwiftUI
import AEXML


@MainActor class PushBrain: ObservableObject {
    
    @State var authToken = ""
    
//    #################################################################################
//    XML data
//    #################################################################################

@Published var xmlDoc: AEXMLDocument = AEXMLDocument()
@Published var computerGroupMembersXML: String = ""
@Published var policyAsXMLScope: String = ""
@Published var currentPolicyAsXML: String = ""
    
    
@Published var processingComplete: Bool = false
    
    //    #################################################################################
    //    Commands
    //    #################################################################################

    @Published var deviceTypes = [ "computers", "computergroups" ]
    @Published var flushCommands = [ "Pending", "Failed", "Pending+Failed" ]
    
    //    #################################################################################
    //    PUSH PACKAGES
    //    #################################################################################
    
    //MARK: - Create Policy and push package
    
    func pushPackage(server: String, as  policyName:String, packageName:String, packageID:Int, computerID:Int, computerName:String,computerUDID:String, resourceType: ResourceType){
        let sem = DispatchSemaphore.init(value: 0)
        var xml:String
        //        let date = String(DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .short))
        print("Running pushPackage")
        print("Url is set as:\(server)")
        print("policyName is set as:\(policyName)")
        print("packageName is set as:\(packageName)")
        print("packageID is set as:\(packageID)")
        print("computerID is set as:\(computerID)")
        print("computerName is set as:\(computerName)")
        print("computerUDID is set as:\(computerUDID)")
        print("resourceType is set as:\(resourceType)")
        
        xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <policy>
        <general>
            <id>0</id>
            <name>\(policyName)</name>
            <enabled>true</enabled>
            <trigger>CHECKIN</trigger>
            <trigger_checkin>true</trigger_checkin>
            <trigger_enrollment_complete>false</trigger_enrollment_complete>
            <trigger_login>false</trigger_login>
            <trigger_logout>false</trigger_logout>
            <trigger_network_state_changed>false</trigger_network_state_changed>
            <trigger_startup>false</trigger_startup>
            <trigger_other/>
            <frequency>Once per computer</frequency>
            <retry_event>check-in</retry_event>
            <retry_attempts>3</retry_attempts>
            <notify_on_each_failed_retry>false</notify_on_each_failed_retry>
            <location_user_only>false</location_user_only>
            <target_drive>/</target_drive>
            <offline>false</offline>
            <date_time_limitations>
                <activation_date/>
                <activation_date_epoch>0</activation_date_epoch>
                <activation_date_utc/>
                <expiration_date/>
                <expiration_date_epoch>0</expiration_date_epoch>
                <expiration_date_utc/>
                <no_execute_on/>
                <no_execute_start/>
                <no_execute_end/>
            </date_time_limitations>
            <network_limitations>
                <minimum_network_connection>No Minimum</minimum_network_connection>
                <any_ip_address>true</any_ip_address>
                <network_segments/>
            </network_limitations>
            <override_default_settings>
                <target_drive>default</target_drive>
                <distribution_point/>
                <force_afp_smb>false</force_afp_smb>
                <sus>default</sus>
                <netboot_server>current</netboot_server>
            </override_default_settings>
            <network_requirements>Any</network_requirements>
            <site>
                <id>-1</id>
                <name>None</name>
            </site>
        </general>
        <scope>
            <all_computers>false</all_computers>
            <computers>
                <computer>
                    <id>\(computerID)</id>
                    <name>\(computerName)</name>
                    <udid>\(computerUDID)</udid>
                </computer>
            </computers>
            <computer_groups/>
            <buildings/>
            <departments/>
            <limit_to_users>
                <user_groups/>
            </limit_to_users>
            <limitations>
                <users/>
                <user_groups/>
                <network_segments/>
                <ibeacons/>
            </limitations>
            <exclusions>
                <computers/>
                <computer_groups/>
                <buildings/>
                <departments/>
                <users/>
                <user_groups/>
                <network_segments/>
                <ibeacons/>
            </exclusions>
        </scope>
        <self_service>
            <use_for_self_service>false</use_for_self_service>
            <self_service_display_name/>
            <install_button_text>Install</install_button_text>
            <reinstall_button_text>Reinstall</reinstall_button_text>
            <self_service_description/>
            <force_users_to_view_description>false</force_users_to_view_description>
            <self_service_icon/>
            <feature_on_main_page>false</feature_on_main_page>
            <self_service_categories/>
            <notification>false</notification>
            <notification>Self Service</notification>
            <notification_subject>Deploy Package</notification_subject>
            <notification_message/>
        </self_service>
        <package_configuration>
            <packages>
                <size>1</size>
                <package>
                    <id>\(String(describing: packageID))</id>
                    <name>\(packageName)</name>
                    <action>Install</action>
                    <fut>false</fut>
                    <feu>false</feu>
                    <update_autorun>false</update_autorun>
                </package>
            </packages>
        </package_configuration>
        <scripts>
            <size>0</size>
        </scripts>
        <printers>
            <size>0</size>
            <leave_existing_default/>
        </printers>
        <dock_items>
            <size>0</size>
        </dock_items>
        <account_maintenance>
            <accounts>
                <size>0</size>
            </accounts>
            <directory_bindings>
                <size>0</size>
            </directory_bindings>
            <management_account>
                <action>doNotChange</action>
            </management_account>
        </account_maintenance>
        <reboot>
            <message>This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu.</message>
            <startup_disk>Current Startup Disk</startup_disk>
            <specify_startup/>
            <no_user_logged_in>Do not restart</no_user_logged_in>
            <user_logged_in>Do not restart</user_logged_in>
            <minutes_until_reboot>5</minutes_until_reboot>
            <start_reboot_timer_immediately>false</start_reboot_timer_immediately>
            <file_vault_2_reboot>false</file_vault_2_reboot>
        </reboot>
        <maintenance>
            <recon>true</recon>
            <reset_name>false</reset_name>
            <install_all_cached_packages>false</install_all_cached_packages>
            <heal>false</heal>
            <prebindings>false</prebindings>
            <permissions>false</permissions>
            <byhost>false</byhost>
            <system_cache>false</system_cache>
            <user_cache>false</user_cache>
            <verify>false</verify>
        </maintenance>
        <files_processes>
            <search_by_path/>
            <delete_file>false</delete_file>
            <locate_file/>
            <update_locate_database>false</update_locate_database>
            <spotlight_search/>
            <search_for_process/>
            <kill_process>false</kill_process>
            <run_command/>
        </files_processes>
        <user_interaction>
            <message_start>Installing Package</message_start>
            <allow_users_to_defer>false</allow_users_to_defer>
            <allow_deferral_until_utc/>
            <allow_deferral_minutes>0</allow_deferral_minutes>
            <message_finish>Package Installed</message_finish>
        </user_interaction>
        <disk_encryption>
            <action>none</action>
        </disk_encryption>
    </policy>
    """
        
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
                let xmldata = xml.data(using: .utf8)
                
                print(url)
                // Request options
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
                request.setValue("application/xml", forHTTPHeaderField: "Accept")
                request.httpBody = xmldata
                let config = URLSessionConfiguration.default
                //API Authentication
                
                //                let loginData = "\(username):\(password)".data(using: String.Encoding.utf8)
                //                let base64EncodedCredential = loginData!.base64EncodedString()
                //
                //
                //
                //                let authString = "Basic \(base64EncodedCredential)"
                
                
                
                let authString = "Bearer \(self.authToken)"
                
                
                config.httpAdditionalHeaders = ["Authorization" : authString]
                URLSession(configuration: config).dataTask(with: request) { (data, response, err) in
                    defer { sem.signal() }
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        print("Bad Credentials")
                        print(response!)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        print("Success! Package pushed.")
                    }
                }.resume()
                
                sem.wait()
            }
            
        }
        
    }
    
    
    
    //    //    #################################################################################
    //    //    PUSH SCRIPTS
    //    //    #################################################################################
    
    
    
    //MARK: - PUSH SCRIPTS
    func pushScript(server: String, as  policyName:String, scriptName:String, scriptID:Int, computerID:Int, computerName:String,computerUDID:String, resourceType: ResourceType){
        //        let sem = DispatchSemaphore.init(value: 0)
//        var xml:String
        let date = String(DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .short))
        
     var xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <policy>
      <general>
        <id>0</id>
        <name>\(date + " | " + policyName)</name>
        <enabled>true</enabled>
        <trigger>CHECKIN</trigger>
        <trigger_checkin>true</trigger_checkin>
        <trigger_enrollment_complete>false</trigger_enrollment_complete>
        <trigger_login>false</trigger_login>
        <trigger_logout>false</trigger_logout>
        <trigger_network_state_changed>false</trigger_network_state_changed>
        <trigger_startup>false</trigger_startup>
        <trigger_other/>
        <frequency>Once per computer</frequency>
        <retry_event>check-in</retry_event>
        <retry_attempts>3</retry_attempts>
        <notify_on_each_failed_retry>false</notify_on_each_failed_retry>
        <location_user_only>false</location_user_only>
        <target_drive>/</target_drive>
        <offline>false</offline>
        <category>
          <id>-1</id>
          <name>No category assigned</name>
        </category>
        <date_time_limitations>
          <activation_date/>
          <activation_date_epoch>0</activation_date_epoch>
          <activation_date_utc/>
          <expiration_date/>
          <expiration_date_epoch>0</expiration_date_epoch>
          <expiration_date_utc/>
          <no_execute_on/>
          <no_execute_start/>
          <no_execute_end/>
        </date_time_limitations>
        <network_limitations>
          <minimum_network_connection>No Minimum</minimum_network_connection>
          <any_ip_address>true</any_ip_address>
          <network_segments/>
        </network_limitations>
        <override_default_settings>
          <target_drive>default</target_drive>
          <distribution_point/>
          <force_afp_smb>false</force_afp_smb>
          <sus>default</sus>
          <netboot_server>current</netboot_server>
        </override_default_settings>
        <network_requirements>Any</network_requirements>
        <site>
          <id>-1</id>
          <name>None</name>
        </site>
      </general>
      <scope>
        <all_computers>false</all_computers>
        <computers>
          <computer>
            <id>\(computerID)</id>
            <name>\(computerName)</name>
            <udid>\(computerUDID)</udid>
          </computer>
        </computers>
        <computer_groups/>
        <buildings/>
        <departments/>
        <limit_to_users>
          <user_groups/>
        </limit_to_users>
        <limitations>
          <users/>
          <user_groups/>
          <network_segments/>
          <ibeacons/>
        </limitations>
        <exclusions>
          <computers/>
          <computer_groups/>
          <buildings/>
          <departments/>
          <users/>
          <user_groups/>
          <network_segments/>
          <ibeacons/>
        </exclusions>
      </scope>
      <self_service>
        <use_for_self_service>false</use_for_self_service>
        <self_service_display_name/>
        <install_button_text>Install</install_button_text>
        <reinstall_button_text>Reinstall</reinstall_button_text>
        <self_service_description/>
        <force_users_to_view_description>false</force_users_to_view_description>
        <self_service_icon/>
        <feature_on_main_page>false</feature_on_main_page>
        <self_service_categories/>
        <notification>false</notification>
        <notification>Self Service</notification>
        <notification_subject>Deploy Script</notification_subject>
        <notification_message/>
      </self_service>
      <package_configuration>
        <packages>
          <size>0</size>
        </packages>
      </package_configuration>
      <scripts>
        <size>1</size>
        <script>
          <id>\(scriptID)</id>
          <name>\(scriptName)</name>
          <priority>After</priority>
          <parameter4/>
          <parameter5/>
          <parameter6/>
          <parameter7/>
          <parameter8/>
          <parameter9/>
          <parameter10/>
          <parameter11/>
        </script>
      </scripts>
      <printers>
        <size>0</size>
        <leave_existing_default/>
      </printers>
      <dock_items>
        <size>0</size>
      </dock_items>
      <account_maintenance>
        <accounts>
          <size>0</size>
        </accounts>
        <directory_bindings>
          <size>0</size>
        </directory_bindings>
        <management_account>
          <action>doNotChange</action>
        </management_account>
      </account_maintenance>
      <reboot>
        <message>This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu.</message>
        <startup_disk>Current Startup Disk</startup_disk>
        <specify_startup/>
        <no_user_logged_in>Do not restart</no_user_logged_in>
        <user_logged_in>Do not restart</user_logged_in>
        <minutes_until_reboot>5</minutes_until_reboot>
        <start_reboot_timer_immediately>false</start_reboot_timer_immediately>
        <file_vault_2_reboot>false</file_vault_2_reboot>
      </reboot>
      <maintenance>
        <recon>false</recon>
        <reset_name>false</reset_name>
        <install_all_cached_packages>false</install_all_cached_packages>
        <heal>false</heal>
        <prebindings>false</prebindings>
        <permissions>false</permissions>
        <byhost>false</byhost>
        <system_cache>false</system_cache>
        <user_cache>false</user_cache>
        <verify>false</verify>
      </maintenance>
      <files_processes>
        <search_by_path/>
        <delete_file>false</delete_file>
        <locate_file/>
        <update_locate_database>false</update_locate_database>
        <spotlight_search/>
        <search_for_process/>
        <kill_process>false</kill_process>
        <run_command/>
      </files_processes>
      <user_interaction>
        <message_start/>
        <allow_users_to_defer>false</allow_users_to_defer>
        <allow_deferral_until_utc/>
        <allow_deferral_minutes>0</allow_deferral_minutes>
        <message_finish/>
      </user_interaction>
      <disk_encryption>
        <action>none</action>
      </disk_encryption>
    </policy>
    """
        
        if URL(string: server) != nil {
            if let serverURL = URL(string: server) {
                let url = serverURL.appendingPathComponent("/JSSResource/policies/id/0")
                
                print("Running InstallPackage policy function - url is set as:\(url)")
                print("resourceType is set as:\(resourceType)")
                // print("xml is set as:\(xml)")
                self.sendRequestAsXML(url: url, authToken: authToken,resourceType: resourceType, xml: self.xmlDoc.root.xml, httpMethod: "PUT")
                
//                appendStatus("Connecting to \(url)...")
            }
        }
    }
    
    
    //    #################################################################################
    //    Create Objects - Push Policies - via XML - END
    //    #################################################################################
    
    
    func sendRequestAsXML(url: URL, authToken: String, resourceType: ResourceType, xml: String, httpMethod: String ) {
                
        let xml = xml
        let xmldata = xml.data(using: .utf8)
        print("Running sendRequestAsXML Pushbrain function - resourceType is set as:\(resourceType)")
        print("url is:\(url)")
        print("xml is:\(xml)")
        print("httpMethod is:\(httpMethod)")

        let headers = [
            "Accept": "application/xml",
            "Content-Type": "application/xml",
            "Authorization": "Bearer \(authToken)"
        ]
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.allHTTPHeaderFields = headers
        request.httpMethod = httpMethod
        request.httpBody = xmldata
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                print("Doing processing of sendRequestAsXML:\(httpMethod)")
                print("Data is:\(data)")
                print("Data is:\(response)")
                
            } else {
                print("Error encountered")
                var text = "\n\nFailed."
                if let error = error {
                    text += " \(error)."
                }
                print(text)
            }
        }
        dataTask.resume()
    }
    
    //    #################################################################################
    //    Error Codes
    //    #################################################################################
    
    @Published var currentResponseCode: String = ""
    
    func sendCommandGeneric (id: Int, command: String, authorisation: String, server: String )  {
        
        print("Sending MDM command:\(command) for id:\(id)")
        
        let semaphore = DispatchSemaphore (value: 0)
        
        let parameters = "<computer_command>\n\t<general>\n\t\t<command>\(command)</command>\n\t</general>\n\t<computers>\n\t\t<computer>\n\t\t\t<id>\(id)</id>\n\t\t</computer>\n\t</computers>\n</computer_command>"
        let postData = parameters.data(using: .utf8)
        var request = URLRequest(url: URL(string: "\(server)/JSSResource/computercommands/command/\(command)")!,timeoutInterval: Double.infinity)
        
        request.httpMethod = "POST"
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("application/xml", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let config = URLSessionConfiguration.default
        let authString = "Bearer \(self.authToken)"
        
        config.httpAdditionalHeaders = ["Authorization" : authString]
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print(String(describing: error))
                semaphore.signal()
                return
            }
            //            print("Returning data:")
            print(String(data: data, encoding: .utf8)!)
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
    func separationLine() {
        print("------------------------------------------------------------------")
    }

    
    func flushCommands(targetId: Int, deviceType: String, command: String, authToken: String, server: String ) async throws {

        print("Running: flushCommands")
        var request = URLRequest(url: URL(string: "\(server)/JSSResource/commandflush/\(deviceType)/id/\(targetId)/status/\(command)")!,timeoutInterval: Double.infinity)
        request.addValue("application/xml", forHTTPHeaderField: "Accept")
        request.addValue("application/xml", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        let config = URLSessionConfiguration.default
        request.httpMethod = "DELETE"
        print("request is:\(request)")
//        print("authToken is:\(authToken)")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            print("Code not 200")
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("statusCode is:\(statusCode)")
            throw JamfAPIError.badResponseCode
        }
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("statusCode is:\(statusCode)")
    }
    
    
    func flushCommandBatch(server: String, authToken: String, selectionComp: Set<ComputerBasicRecord.ID>, selectedCommand: String, deviceType: String) async {
        separationLine()
        print("Running: flushCommandBatch")
        print("Set processingComplete to false")
        self.processingComplete = true
        print(String(describing: self.processingComplete))
        print("selectionComp is:\(selectionComp)")
        
        for eachItem in selectionComp {
            separationLine()
            print("Items as Dictionary is \(eachItem)")
            let compID = eachItem
            print("Current compID is:\(compID)")
            print("Run:getPolicyAsXML")
            
            Task {
                try await self.flushCommands(targetId: compID, deviceType: deviceType, command: selectedCommand, authToken: authToken, server: server)
            }
            separationLine()
            print("Finished - Set processingComplete to true")
            self.processingComplete = true
            print(String(describing: self.processingComplete))
        }
    }
}
