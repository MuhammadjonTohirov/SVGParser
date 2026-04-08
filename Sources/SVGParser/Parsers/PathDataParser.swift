//
//  PathDataParser.swift
//  SVGParser
//
//  Created by applebro on 18/12/25.
//

import SwiftUI

/// Parses SVG path data strings (e.g. "M10 10 L20 20 C...") into SwiftUI `Path` objects.
///
/// Supports commands: M/m, L/l, H/h, V/v, C/c, S/s, Q/q, T/t, A/a, Z/z.
/// Handles implicit repeated parameters and negative-number separators per SVG spec.
public struct PathDataParser {

    // MARK: - Result

    /// Parsed SVG path with geometry metadata for arrow/indicator placement.
    public struct ParsedPath: Sendable {
        public let path: Path
        public let endPoint: CGPoint
        /// Tangent angle (radians) at the path's final segment end — useful for arrow overlays.
        public let endTangentAngle: CGFloat?
        /// Whether this path should be rendered filled (e.g. dots on Arabic letters) vs stroked.
        public var isFilled: Bool = false

        public init(path: Path, endPoint: CGPoint, endTangentAngle: CGFloat?, isFilled: Bool = false) {
            self.path = path
            self.endPoint = endPoint
            self.endTangentAngle = endTangentAngle
            self.isFilled = isFilled
        }
    }

    // MARK: - Public API

    /// Parse path data string into a SwiftUI `Path`.
    static func parsePathData(_ pathData: String) throws -> Path {
        try parse(pathData).path
    }

    /// Parse path data string into a `ParsedPath` with end-point and tangent angle.
    public static func parse(_ pathData: String) throws -> ParsedPath {
        let trimmed = pathData.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SVGError.invalidPathData }

        let tokens = PathTokenizer.tokenize(trimmed)
        return try buildPath(from: tokens)
    }
}
