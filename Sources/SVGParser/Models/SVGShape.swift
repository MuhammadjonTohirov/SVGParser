//
//  SVGShape.swift
//  SVGParser
//
//  Created by applebro on 06/09/25.
//

import SwiftUI

/// A SwiftUI Shape created from SVG path data.
public struct SVGShape: Shape {
    public let svgPath: Path
    /// The final point of the path — useful for placing indicators or arrows.
    public let endPoint: CGPoint?
    /// Tangent angle (radians) at the path's last segment — useful for orienting arrows.
    public let endTangentAngle: CGFloat?

    public init(path: Path) {
        self.svgPath = path
        self.endPoint = nil
        self.endTangentAngle = nil
    }

    public init(parsed: PathDataParser.ParsedPath) {
        self.svgPath = parsed.path
        self.endPoint = parsed.endPoint
        self.endTangentAngle = parsed.endTangentAngle
    }

    public func path(in rect: CGRect) -> Path {
        svgPath
    }
}
