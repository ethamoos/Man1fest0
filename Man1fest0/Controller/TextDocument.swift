//
//  TextDocument.swift
//  Man1fest0
//
//  Created by Amos Deane on 20/01/2025.
//



import UniformTypeIdentifiers
import SwiftUI



struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.plainText, .xml]
    }
    
    var text = ""
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
