//
//  PathDataParser+BuildPath.swift
//  SVGParser
//
//  Created by applebro on 17/03/26.
//

import SwiftUI

// MARK: - Path Building & Token Reading

extension PathDataParser {

    /// Walks through tokens, builds the path, and tracks tangent angle.
    /// Handles implicit command repetition per SVG spec:
    /// - Extra coordinates after M/m are treated as L/l
    /// - Extra coordinates after other commands repeat the same command
    static func buildPath(from tokens: [PathToken]) throws -> ParsedPath {
        var state = PathBuilderState()
        var index = 0

        while index < tokens.count {
            guard case .command(let cmd) = tokens[index] else {
                index += 1
                continue
            }
            index += 1

            let isRelative = cmd.isLowercase
            let norm = cmd.uppercased().first!
            var isFirst = true

            // Consume parameter groups, repeating the command while numbers remain.
            while true {
                let consumed: Int

                switch norm {

                // MARK: Move To (M)
                case "M":
                    guard let pt = readPoint(tokens, at: index) else {
                        if isFirst { throw SVGError.invalidPathData }
                        consumed = 0; break
                    }
                    let dest = isRelative ? state.current.adding(pt) : pt
                    if isFirst {
                        state.moveTo(dest)
                    } else {
                        // SVG spec: implicit coords after M become L
                        state.lineTo(dest)
                    }
                    consumed = 2

                // MARK: Line To (L)
                case "L":
                    guard let pt = readPoint(tokens, at: index) else { consumed = 0; break }
                    state.lineTo(isRelative ? state.current.adding(pt) : pt)
                    consumed = 2

                // MARK: Horizontal Line (H)
                case "H":
                    guard let x = readNumber(tokens, at: index) else { consumed = 0; break }
                    let absX = isRelative ? state.current.x + x : x
                    state.lineTo(CGPoint(x: absX, y: state.current.y))
                    consumed = 1

                // MARK: Vertical Line (V)
                case "V":
                    guard let y = readNumber(tokens, at: index) else { consumed = 0; break }
                    let absY = isRelative ? state.current.y + y : y
                    state.lineTo(CGPoint(x: state.current.x, y: absY))
                    consumed = 1

                // MARK: Cubic Bezier (C)
                case "C":
                    guard let (c1, c2, end) = readCubicParams(tokens, at: index) else { consumed = 0; break }
                    let base = isRelative ? state.current : .zero
                    state.cubicTo(base.adding(end), c1: base.adding(c1), c2: base.adding(c2))
                    consumed = 6

                // MARK: Smooth Cubic Bezier (S)
                case "S":
                    guard let (c2, end) = readTwoPoints(tokens, at: index) else { consumed = 0; break }
                    let c1 = state.reflectedCubicControl
                    let base = isRelative ? state.current : .zero
                    state.cubicTo(base.adding(end), c1: c1, c2: base.adding(c2))
                    consumed = 4

                // MARK: Quadratic Bezier (Q)
                case "Q":
                    guard let (ctrl, end) = readTwoPoints(tokens, at: index) else { consumed = 0; break }
                    let base = isRelative ? state.current : .zero
                    state.quadTo(base.adding(end), control: base.adding(ctrl))
                    consumed = 4

                // MARK: Smooth Quadratic Bezier (T)
                case "T":
                    guard let pt = readPoint(tokens, at: index) else { consumed = 0; break }
                    let ctrl = state.reflectedQuadControl
                    state.quadTo(isRelative ? state.current.adding(pt) : pt, control: ctrl)
                    consumed = 2

                // MARK: Arc (A)
                case "A":
                    guard let arc = readArcParams(tokens, at: index) else { consumed = 0; break }
                    let endPt = isRelative ? state.current.adding(arc.end) : arc.end
                    let arcTangent = SVGArcConverter.addArc(
                        to: &state.path, from: state.current, to: endPt,
                        rx: arc.rx, ry: arc.ry,
                        rotation: arc.rotation,
                        largeArc: arc.largeArc,
                        sweep: arc.sweep
                    )
                    if let arcTangent {
                        state.setTangentAngle(arcTangent)
                    }
                    state.current = endPt
                    consumed = 7

                // MARK: Close Path (Z)
                case "Z":
                    state.closePath()
                    consumed = 0

                default:
                    consumed = 0
                }

                if consumed == 0 { break }
                index += consumed
                isFirst = false
            }
        }

        return ParsedPath(
            path: state.path,
            endPoint: state.current,
            endTangentAngle: state.endTangentAngle
        )
    }

    // MARK: - Token Readers

    private static func readNumber(_ tokens: [PathToken], at i: Int) -> CGFloat? {
        guard i < tokens.count, case .number(let v) = tokens[i] else { return nil }
        return v
    }

    private static func readPoint(_ tokens: [PathToken], at i: Int) -> CGPoint? {
        guard let x = readNumber(tokens, at: i),
              let y = readNumber(tokens, at: i + 1) else { return nil }
        return CGPoint(x: x, y: y)
    }

    private static func readCubicParams(_ tokens: [PathToken], at i: Int) -> (CGPoint, CGPoint, CGPoint)? {
        guard let c1 = readPoint(tokens, at: i),
              let c2 = readPoint(tokens, at: i + 2),
              let end = readPoint(tokens, at: i + 4) else { return nil }
        return (c1, c2, end)
    }

    private static func readTwoPoints(_ tokens: [PathToken], at i: Int) -> (CGPoint, CGPoint)? {
        guard let p1 = readPoint(tokens, at: i),
              let p2 = readPoint(tokens, at: i + 2) else { return nil }
        return (p1, p2)
    }

    struct ArcParams {
        let rx: CGFloat, ry: CGFloat, rotation: CGFloat
        let largeArc: Bool, sweep: Bool
        let end: CGPoint
    }

    private static func readArcParams(_ tokens: [PathToken], at i: Int) -> ArcParams? {
        guard i + 6 < tokens.count,
              let rx = readNumber(tokens, at: i),
              let ry = readNumber(tokens, at: i + 1),
              let rot = readNumber(tokens, at: i + 2),
              let la = readNumber(tokens, at: i + 3),
              let sw = readNumber(tokens, at: i + 4),
              let end = readPoint(tokens, at: i + 5) else { return nil }
        return ArcParams(rx: rx, ry: ry, rotation: rot, largeArc: la != 0, sweep: sw != 0, end: end)
    }
}
