//
//  ShapeToPathConverter.swift
//  SVGParser
//
//  Created by applebro on 18/12/25.
//

import Foundation
import CoreGraphics

/// Helper to convert standard SVG shapes into Path Data (d attribute) strings.
enum ShapeToPathConverter {

    static func circleToPathData(cx: CGFloat, cy: CGFloat, r: CGFloat) -> String {
        ellipseToPathData(cx: cx, cy: cy, rx: r, ry: r)
    }

    static func rectToPathData(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> String {
        "M \(x),\(y) L \(x + width),\(y) L \(x + width),\(y + height) L \(x),\(y + height) Z"
    }

    static func ellipseToPathData(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat) -> String {
        // Magic number for cubic bezier ellipse approximation: 4/3 * tan(π/8) ≈ 0.552284749831
        let kX = rx * 0.552284749831
        let kY = ry * 0.552284749831

        let top = cy - ry
        let bottom = cy + ry
        let left = cx - rx
        let right = cx + rx

        let topControl = top + kY
        let bottomControl = bottom - kY
        let leftControl = left + kX
        let rightControl = right - kX

        return """
        M \(cx),\(top) \
        C \(cx + kX),\(top) \(right),\(topControl) \(right),\(cy) \
        C \(right),\(cy + kY) \(rightControl),\(bottom) \(cx),\(bottom) \
        C \(cx - kX),\(bottom) \(left),\(bottomControl) \(left),\(cy) \
        C \(left),\(cy - kY) \(leftControl),\(top) \(cx),\(top) Z
        """
    }

    static func lineToPathData(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) -> String {
        "M \(x1),\(y1) L \(x2),\(y2)"
    }

    static func polygonToPathData(points: String) -> String {
        pointsToPathData(points: points, closed: true)
    }

    static func polylineToPathData(points: String) -> String {
        pointsToPathData(points: points, closed: false)
    }
    
    // MARK: - Private Helpers

    private static func pointsToPathData(points: String, closed: Bool) -> String {
        let coordinates = parseCoordinates(from: points)
        guard !coordinates.isEmpty else { return "" }

        var pathData = "M \(coordinates[0].x),\(coordinates[0].y)"
        for i in 1..<coordinates.count {
            pathData += " L \(coordinates[i].x),\(coordinates[i].y)"
        }
        if closed { pathData += " Z" }
        return pathData
    }

    private static func parseCoordinates(from pointsString: String) -> [CGPoint] {
        let cleanedString = pointsString.trimmingCharacters(in: .whitespacesAndNewlines)
        let pointPairs = cleanedString.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        
        var coordinates: [CGPoint] = []
        
        for pointPair in pointPairs {
            let trimmed = pointPair.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            let components = trimmed.components(separatedBy: ",")
            if components.count == 2,
               let x = Float(components[0]),
               let y = Float(components[1]) {
                coordinates.append(CGPoint(x: CGFloat(x), y: CGFloat(y)))
            }
        }
        return coordinates
    }
}
