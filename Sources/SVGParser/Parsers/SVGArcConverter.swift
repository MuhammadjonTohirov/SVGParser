//
//  SVGArcConverter.swift
//  SVGParser
//
//  Created by applebro on 17/03/26.
//

import SwiftUI

/// Converts SVG arc commands to cubic bezier curve(s).
/// Implements the full SVG spec endpoint-to-center arc parameterization algorithm,
/// including elliptical arcs and automatic radius scaling.
enum SVGArcConverter {

    /// Appends cubic bezier curves approximating the arc to the given path.
    /// Returns the tangent angle (radians) at the arc endpoint.
    @discardableResult
    static func addArc(
        to path: inout Path,
        from p1: CGPoint, to p2: CGPoint,
        rx rawRx: CGFloat, ry rawRy: CGFloat,
        rotation: CGFloat, largeArc: Bool, sweep: Bool
    ) -> CGFloat? {
        // Degenerate cases: same endpoints or zero radii → straight line
        guard p1 != p2, rawRx > 0, rawRy > 0 else {
            path.addLine(to: p2)
            return nil
        }

        let phi = rotation * .pi / 180
        let cosPhi = cos(phi), sinPhi = sin(phi)

        // Step 1: Transform to unit-circle space
        let dx = (p1.x - p2.x) / 2, dy = (p1.y - p2.y) / 2
        let x1p = cosPhi * dx + sinPhi * dy
        let y1p = -sinPhi * dx + cosPhi * dy

        // Step 2: Scale radii if too small to reach the endpoint
        var rx = abs(rawRx), ry = abs(rawRy)
        let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
        if lambda > 1 { let s = sqrt(lambda); rx *= s; ry *= s }

        // Step 3: Compute center in transformed space
        let rxSq = rx * rx, rySq = ry * ry
        let x1pSq = x1p * x1p, y1pSq = y1p * y1p
        var sq = max(0, (rxSq * rySq - rxSq * y1pSq - rySq * x1pSq) / (rxSq * y1pSq + rySq * x1pSq))
        sq = sqrt(sq) * (largeArc == sweep ? -1 : 1)
        let cxp = sq * rx * y1p / ry
        let cyp = -sq * ry * x1p / rx

        // Step 4: Transform center back to original space
        let midX = (p1.x + p2.x) / 2, midY = (p1.y + p2.y) / 2
        let cx = cosPhi * cxp - sinPhi * cyp + midX
        let cy = sinPhi * cxp + cosPhi * cyp + midY

        // Step 5: Compute start angle and sweep
        let theta1 = atan2((y1p - cyp) / ry, (x1p - cxp) / rx)
        var dTheta = atan2((-y1p - cyp) / ry, (-x1p - cxp) / rx) - theta1
        if sweep && dTheta < 0 { dTheta += 2 * .pi }
        if !sweep && dTheta > 0 { dTheta -= 2 * .pi }

        // Step 6: Split into ≤90° segments, each approximated by one cubic bezier
        let segments = max(1, Int(ceil(abs(dTheta) / (.pi / 2))))
        let segAngle = dTheta / CGFloat(segments)

        for i in 0..<segments {
            let a1 = theta1 + CGFloat(i) * segAngle
            let a2 = a1 + segAngle
            appendSegment(to: &path, cx: cx, cy: cy, rx: rx, ry: ry, phi: phi, a1: a1, a2: a2)
        }

        // Compute tangent at arc endpoint
        let endAngle = theta1 + dTheta
        let tdx = -rx * sin(endAngle), tdy = ry * cos(endAngle)
        let tangentX = cosPhi * tdx - sinPhi * tdy
        let tangentY = sinPhi * tdx + cosPhi * tdy
        return atan2(tangentY, tangentX)
    }

    // MARK: - Private

    /// Approximates a single arc segment (≤ 90°) as one cubic bezier curve.
    private static func appendSegment(
        to path: inout Path,
        cx: CGFloat, cy: CGFloat,
        rx: CGFloat, ry: CGFloat,
        phi: CGFloat, a1: CGFloat, a2: CGFloat
    ) {
        let alpha = sin(a2 - a1) * (sqrt(4 + 3 * pow(tan((a2 - a1) / 2), 2)) - 1) / 3
        let cosPhi = cos(phi), sinPhi = sin(phi)

        func point(at angle: CGFloat) -> CGPoint {
            let x = rx * cos(angle), y = ry * sin(angle)
            return CGPoint(x: cosPhi * x - sinPhi * y + cx, y: sinPhi * x + cosPhi * y + cy)
        }

        func tangent(at angle: CGFloat) -> CGPoint {
            let dx = -rx * sin(angle), dy = ry * cos(angle)
            return CGPoint(x: cosPhi * dx - sinPhi * dy, y: sinPhi * dx + cosPhi * dy)
        }

        let p1 = point(at: a1), p2 = point(at: a2)
        let t1 = tangent(at: a1), t2 = tangent(at: a2)

        path.addCurve(
            to: p2,
            control1: CGPoint(x: p1.x + alpha * t1.x, y: p1.y + alpha * t1.y),
            control2: CGPoint(x: p2.x - alpha * t2.x, y: p2.y - alpha * t2.y)
        )
    }
}
