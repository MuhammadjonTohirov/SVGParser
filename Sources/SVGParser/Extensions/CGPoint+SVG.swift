//
//  CGPoint+SVG.swift
//  SVGParser
//
//  Created by applebro on 08/04/26.
//

import CoreGraphics

extension CGPoint {
    /// Reflects this point over another point: `2 * self - other`.
    func svgReflected(over other: CGPoint) -> CGPoint {
        CGPoint(x: 2 * x - other.x, y: 2 * y - other.y)
    }

    /// Vector addition for relative SVG coordinate calculation.
    func adding(_ other: CGPoint) -> CGPoint {
        CGPoint(x: x + other.x, y: y + other.y)
    }

    /// Tangent angle (radians) from this point to another.
    /// Returns `nil` if the points are effectively coincident.
    func tangentAngle(to other: CGPoint) -> CGFloat? {
        let dx = other.x - x, dy = other.y - y
        guard abs(dx) > 1e-4 || abs(dy) > 1e-4 else { return nil }
        return atan2(dy, dx)
    }
}
