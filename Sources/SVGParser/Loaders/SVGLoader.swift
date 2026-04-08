//
//  SVGLoader.swift
//  SVGParser
//
//  Created by applebro on 18/12/25.
//

import Foundation

struct SVGLoader {
    /// Loads SVG content string from a file in the given bundle.
    static func loadSVGFromFile(_ fileName: String, bundle: Bundle = .main) throws -> String {
        let resourceName = fileName.hasSuffix(".svg")
            ? fileName.replacingOccurrences(of: ".svg", with: "")
            : fileName

        // Try top-level first
        if let url = bundle.url(forResource: resourceName, withExtension: "svg") {
            return try String(contentsOf: url)
        }

        // Search subdirectories
        if let bundleURL = bundle.resourceURL,
           let enumerator = FileManager.default.enumerator(
               at: bundleURL,
               includingPropertiesForKeys: nil,
               options: [.skipsHiddenFiles]
           ) {
            let target = "\(resourceName).svg"
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.lastPathComponent == target {
                    return try String(contentsOf: fileURL)
                }
            }
        }

        throw SVGError.fileNotFound
    }
}
