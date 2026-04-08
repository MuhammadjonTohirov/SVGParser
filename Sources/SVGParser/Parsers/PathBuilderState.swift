//
//  PathBuilderState.swift
//  SVGParser
//
//  Created by applebro on 17/03/26.
//

import SwiftUI

/// Mutable state used while walking tokens and constructing the path.
/// Tracks pen position, control points, and end-of-path tangent for arrow placement.
struct PathBuilderState {
    var path = Path()
    var current: CGPoint = .zero
    var subpathStart: CGPoint = .zero

    // Separate control-point tracking per SVG spec (S reflects cubic, T reflects quad)
    var lastCubicControl: CGPoint?
    var lastQuadControl: CGPoint?

    // End-of-path metadata for arrow placement
    var endTangentAngle: CGFloat?

    // MARK: - Mutations

    mutating func moveTo(_ pt: CGPoint) {
        current = pt
        subpathStart = pt
        path.move(to: pt)
        clearControls()
    }

    mutating func lineTo(_ pt: CGPoint) {
        tryUpdateTangent(from: current, to: pt)
        path.addLine(to: pt)
        current = pt
        clearControls()
    }

    mutating func cubicTo(_ end: CGPoint, c1: CGPoint, c2: CGPoint) {
        if !tryUpdateTangent(from: c2, to: end) {
            if !tryUpdateTangent(from: c1, to: end) {
                tryUpdateTangent(from: current, to: end)
            }
        }
        path.addCurve(to: end, control1: c1, control2: c2)
        current = end
        lastCubicControl = c2
        lastQuadControl = nil
    }

    mutating func quadTo(_ end: CGPoint, control: CGPoint) {
        if !tryUpdateTangent(from: control, to: end) {
            tryUpdateTangent(from: current, to: end)
        }
        path.addQuadCurve(to: end, control: control)
        current = end
        lastQuadControl = control
        lastCubicControl = nil
    }

    mutating func closePath() {
        tryUpdateTangent(from: current, to: subpathStart)
        path.closeSubpath()
        current = subpathStart
        clearControls()
    }

    // MARK: - Reflected Control Points

    var reflectedCubicControl: CGPoint {
        guard let last = lastCubicControl else { return current }
        return current.svgReflected(over: last)
    }

    var reflectedQuadControl: CGPoint {
        guard let last = lastQuadControl else { return current }
        return current.svgReflected(over: last)
    }

    // MARK: - Tangent

    mutating func setTangentAngle(_ angle: CGFloat) {
        endTangentAngle = angle
    }

    // MARK: - Private Helpers

    @discardableResult
    private mutating func tryUpdateTangent(from: CGPoint, to: CGPoint) -> Bool {
        guard let angle = from.tangentAngle(to: to) else { return false }
        endTangentAngle = angle
        return true
    }

    private mutating func clearControls() {
        lastCubicControl = nil
        lastQuadControl = nil
    }
}
