//
//  SVGComponent.swift
//  SVGParser
//
//  Created by applebro on 06/09/25.
//

import SwiftUI

/// Container for multi-path SVG components (main form, dots, diacritics, etc.)
public struct SVGComponent: Sendable {
    private let originalPaths: [PathDataParser.ParsedPath]
    public private(set) var allPaths: [PathDataParser.ParsedPath]
    public var isReversed: Bool {
        didSet {
            guard oldValue != isReversed else { return }
            allPaths = isReversed ? originalPaths.map { $0.reversed() } : originalPaths
        }
    }

    public init(paths: [PathDataParser.ParsedPath], isReversed: Bool = false) {
        self.originalPaths = paths
        self.isReversed = isReversed
        self.allPaths = isReversed ? paths.map { $0.reversed() } : paths
    }

    /// The main form (usually the first path).
    public var mainForm: PathDataParser.ParsedPath? { allPaths.first }

    /// Dots and diacritics (all paths except the first).
    public var dotsAndDiacritics: [PathDataParser.ParsedPath] {
        allPaths.count > 1 ? Array(allPaths.dropFirst()) : []
    }

    /// Get a specific path by index.
    public func path(at index: Int) -> PathDataParser.ParsedPath? {
        guard index >= 0, index < allPaths.count else { return nil }
        return allPaths[index]
    }

    /// The number of components.
    public var count: Int { allPaths.count }
}
