//
//  SVGPathConverter+Component.swift
//  SVGParser
//
//  Created by applebro on 06/09/25.
//

import Foundation

public extension SVGPathConverter {
    /// Create an SVG component from SVG string.
    static func pathComponentFromSVGString(_ svgString: String, isReversed: Bool = false) throws -> SVGComponent {
        let paths = try pathsFromSVGString(svgString)
        return SVGComponent(paths: paths, isReversed: isReversed)
    }

    /// Create an SVG component from SVG file.
    static func pathComponentFromSVGFile(_ fileName: String, isReversed: Bool = false, bundle: Bundle = .main) throws -> SVGComponent {
        let paths = try pathsFromSVGFile(fileName, bundle: bundle)
        return SVGComponent(paths: paths, isReversed: isReversed)
    }
}
