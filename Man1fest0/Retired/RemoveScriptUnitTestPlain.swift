import Foundation

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

struct ScriptEntry {
    var id: Int?
    var name: String
}

func parseScripts(from xml: String) -> [ScriptEntry] {
    var results: [ScriptEntry] = []
    // Simple approach: find <script>...</script> blocks
    let pattern = "(?s)<script>.*?<\\/script>"
    guard let re = try? NSRegularExpression(pattern: pattern, options: []) else { return results }
    let range = NSRange(xml.startIndex..., in: xml)
    let matches = re.matches(in: xml, options: [], range: range)
    for m in matches {
        if let r = Range(m.range, in: xml) {
            let block = String(xml[r])
            // extract id
            let idPattern = "<id>\\s*(\\d+)\\s*<\\/id>"
            let namePattern = "<name>\\s*([^<]+?)\\s*<\\/name>"
            var idVal: Int? = nil
            if let idRe = try? NSRegularExpression(pattern: idPattern, options: []) {
                if let idMatch = idRe.firstMatch(in: block, options: [], range: NSRange(block.startIndex..., in: block)) {
                    if let idRange = Range(idMatch.range(at: 1), in: block) {
                        idVal = Int(block[idRange])
                    }
                }
            }
            var nameVal = ""
            if let nameRe = try? NSRegularExpression(pattern: namePattern, options: []) {
                if let nameMatch = nameRe.firstMatch(in: block, options: [], range: NSRange(block.startIndex..., in: block)) {
                    if let nameRange = Range(nameMatch.range(at: 1), in: block) {
                        nameVal = String(block[nameRange])
                    }
                }
            }
            if !nameVal.isEmpty {
                results.append(ScriptEntry(id: idVal, name: nameVal))
            }
        }
    }
    return results
}

func findTargetScript(scripts: [ScriptEntry], selectedName: String, selectedId: Int?) -> ScriptEntry? {
    for s in scripts {
        if let selId = selectedId, selId > 0 {
            if let id = s.id, id == selId { return s }
        } else {
            let xmlName = s.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let selName = selectedName.trimmingCharacters(in: .whitespacesAndNewlines)
            if xmlName.caseInsensitiveCompare(selName) == .orderedSame { return s }
        }
    }
    return nil
}

let scripts = parseScripts(from: sampleXML)
print("Parsed scripts: \(scripts)")

let tests: [(String, Int?)] = [
    ("", 111),
    ("  0_download_file  ", nil),
    ("FLUSH ALL FILES", nil),
    ("installmacos_script_to_file", 848),
    ("Nonexistent", nil),
    ("", 0)
]

for (name, id) in tests {
    if let found = findTargetScript(scripts: scripts, selectedName: name, selectedId: id) {
        print("Test(\(String(describing: name)), \(String(describing: id))) -> Found id=\(String(describing: found.id)), name=\(found.name)")
    } else {
        print("Test(\(String(describing: name)), \(String(describing: id))) -> No match")
    }
}
