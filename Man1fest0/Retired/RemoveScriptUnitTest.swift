import Foundation
import AEXML

// Lightweight test harness to exercise XmlBrain.removeScriptFromPolicy matching logic.
// This is not an XCTest but a runnable Swift file for manual testing inside the app or a playground.

let sampleXML = """
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<policy>
	<general>
		<id>10122</id>
		<name>Aardvark 2025</name>
	</general>
	<scripts>
		<size>4</size>
		<script>
			<id>110</id>
			<name>Flush All Files</name>
			<priority>After</priority>
		</script>
		<script>
			<id>111</id>
			<name>01 Installomator</name>
			<priority>After</priority>
		</script>
		<script>
			<id>112</id>
			<name>0_download_file</name>
			<priority>After</priority>
		</script>
		<script>
			<id>848</id>
			<name>installmacos_script_to_file</name>
			<priority>After</priority>
		</script>
	</scripts>
</policy>
"""

func parseAEXML(_ xml: String) -> AEXMLDocument? {
    do {
        let doc = try AEXMLDocument(xml: xml)
        return doc
    } catch {
        print("Failed to parse XML: \(error)")
        return nil
    }
}

// Load XmlBrain from project if possible - minimal shim to call the function under test.
// If XmlBrain is not accessible here, copy the matching logic into a local function for testing.

// Local copy of the matching logic used by XmlBrain.removeScriptFromPolicy
func findTargetScript(in xmlDoc: AEXMLDocument, selectedScriptName: String, selectedScriptId: Int?) -> AEXMLElement? {
    let scripts = xmlDoc.root["scripts"].children
    let target = scripts.first { elem in
        let xmlIdRaw = elem["id"].string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let selId = selectedScriptId, selId > 0 {
            if let xmlId = Int(xmlIdRaw) {
                return xmlId == selId
            } else {
                return false
            }
        } else {
            let xmlName = elem["name"].string.trimmingCharacters(in: .whitespacesAndNewlines)
            let selName = selectedScriptName.trimmingCharacters(in: .whitespacesAndNewlines)
            return xmlName.caseInsensitiveCompare(selName) == .orderedSame
        }
    }
    return target
}

if let doc = parseAEXML(sampleXML) {
    let tests: [(String, Int?)] = [
        ("", 111),
        ("  0_download_file  ", nil),
        ("FLUSH ALL FILES", nil),
        ("installmacos_script_to_file", 848),
        ("Nonexistent", nil),
        ("", 0)
    ]

    for (name, id) in tests {
        if let found = findTargetScript(in: doc, selectedScriptName: name, selectedScriptId: id) {
            print("Test(\(String(describing: name)), \(String(describing: id))) -> Found id=\(found["id"].string), name=\(found["name"].string)")
        } else {
            print("Test(\(String(describing: name)), \(String(describing: id))) -> No match")
        }
    }
} else {
    print("Failed to construct XML doc for tests")
}
