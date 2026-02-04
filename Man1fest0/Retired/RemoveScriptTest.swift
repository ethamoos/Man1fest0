import Foundation

// Self-contained test harness for removeScriptFromPolicy matching/removal logic
// Uses Foundation.XMLDocument so it can be run with `swift` on macOS without AEXML.

let sample = """
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

func xmlDocument(from string: String) -> XMLDocument? {
    do {
        let doc = try XMLDocument(xmlString: string, options: .nodePrettyPrint)
        return doc
    } catch {
        print("XML parse error: \(error)")
        return nil
    }
}

// Mimic the matching logic we added to XmlBrain.removeScriptFromPolicy
func removeScriptFromPolicyTest(xmlDoc: XMLDocument, selectedScriptName: String, selectedScriptId: Int?) {
    guard let scriptsNode = try? xmlDoc.nodes(forXPath: "/policy/scripts/script") as? [XMLElement] else {
        print("No script nodes found")
        return
    }

    print("Scripts found:")
    for node in scriptsNode {
        let id = node.elements(forName: "id").first?.stringValue ?? ""
        let name = node.elements(forName: "name").first?.stringValue ?? ""
        print(" id=\(id) name=\(name)")
    }

    // find target
    var targetIndex: Int? = nil
    for (i, elem) in scriptsNode.enumerated() {
        let xmlIdRaw = elem.elements(forName: "id").first?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let selId = selectedScriptId, selId > 0 {
            if let xmlId = Int(xmlIdRaw), xmlId == selId {
                targetIndex = i; break
            }
        } else {
            let xmlName = elem.elements(forName: "name").first?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let selName = selectedScriptName.trimmingCharacters(in: .whitespacesAndNewlines)
            if xmlName.caseInsensitiveCompare(selName) == .orderedSame {
                targetIndex = i; break
            }
        }
    }

    if let idx = targetIndex {
        let nodeToRemove = scriptsNode[idx]
        print("Removing node: \(nodeToRemove.xmlString)")
        nodeToRemove.detach()
    } else {
        print("Could not find script with id '\(selectedScriptId.map { String($0) } ?? "nil")' or name '\(selectedScriptName)'")
    }
}

// Run tests
if let doc = xmlDocument(from: sample) {
    print("Original scripts:\n\(try! doc.nodes(forXPath: "/policy/scripts").first!.xmlString)\n")

    removeScriptFromPolicyTest(xmlDoc: doc, selectedScriptName: "", selectedScriptId: 111)
    print("After removing id 111:\n\(try! doc.nodes(forXPath: "/policy/scripts").first!.xmlString)\n")

    removeScriptFromPolicyTest(xmlDoc: doc, selectedScriptName: "  0_download_file  ", selectedScriptId: nil)
    print("After removing name '0_download_file':\n\(try! doc.nodes(forXPath: "/policy/scripts").first!.xmlString)\n")

    removeScriptFromPolicyTest(xmlDoc: doc, selectedScriptName: "", selectedScriptId: 0)
    print("After attempting to remove id 0 (no-op):\n\(try! doc.nodes(forXPath: "/policy/scripts").first!.xmlString)\n")

    removeScriptFromPolicyTest(xmlDoc: doc, selectedScriptName: "FLUSH ALL FILES", selectedScriptId: nil)
    print("After removing name 'FLUSH ALL FILES' (case-insensitive):\n\(try! doc.nodes(forXPath: "/policy/scripts").first!.xmlString)\n")

    print("Done tests")
}
else {
    print("Failed to parse sample XML")
}