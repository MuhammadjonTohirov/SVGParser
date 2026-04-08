//
//  SVGMultiPathShape.swift
//  SVGParser
//
//  Created by applebro on 06/09/25.
//

import SwiftUI

/// A SwiftUI Shape that combines multiple paths.
public struct SVGMultiPathShape: Shape {
    public let svgPaths: [Path]

    public init(paths: [Path]) {
        self.svgPaths = paths
    }

    public init(parsedPaths: [PathDataParser.ParsedPath]) {
        self.svgPaths = parsedPaths.map(\.path)
    }

    public func path(in rect: CGRect) -> Path {
        var combinedPath = Path()
        for svgPath in svgPaths {
            combinedPath.addPath(svgPath)
        }
        return combinedPath
    }

    /// Get individual paths (useful for separate styling or tracing).
    public var individualPaths: [Path] { svgPaths }
}
