//
//  ParsedPath+Reversed.swift
//  SVGParser
//
//  Created by applebro on 21/03/26.
//

import SwiftUI

extension PathDataParser.ParsedPath {
    public func reversed() -> Self {
        let reversedPath = ReversedPathBuilder.build(from: path.cgPath)
        let metadata = ReversedPathMetadata(cgPath: reversedPath.cgPath)

        return Self(
            path: reversedPath,
            endPoint: metadata.endPoint,
            endTangentAngle: metadata.endTangentAngle,
            isFilled: isFilled
        )
    }
}

private struct ReversedPathBuilder {
    static func build(from cgPath: CGPath) -> Path {
        let subpaths = PathSubpath.extract(from: cgPath)
        var reversedPath = Path()

        for subpath in subpaths {
            let startPoint = subpath.isClosed ? subpath.startPoint : subpath.endPoint
            reversedPath.move(to: startPoint)

            for segment in subpath.segments.reversed() {
                segment.reversed().append(to: &reversedPath)
            }

            if subpath.isClosed {
                reversedPath.closeSubpath()
            }
        }

        return reversedPath
    }
}

private struct PathSubpath {
    let startPoint: CGPoint
    let segments: [PathSegment]
    let isClosed: Bool

    var endPoint: CGPoint {
        segments.last?.endPoint ?? startPoint
    }

    static func extract(from cgPath: CGPath) -> [PathSubpath] {
        var subpaths: [PathSubpath] = []
        var startPoint: CGPoint?
        var currentPoint: CGPoint?
        var segments: [PathSegment] = []
        var isClosed = false

        func flushCurrentSubpath() {
            guard let startPoint else { return }
            subpaths.append(
                PathSubpath(
                    startPoint: startPoint,
                    segments: segments,
                    isClosed: isClosed
                )
            )
            segments.removeAll(keepingCapacity: false)
            isClosed = false
            currentPoint = nil
        }

        cgPath.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                flushCurrentSubpath()

                let point = element.pointee.points[0]
                startPoint = point
                currentPoint = point

            case .addLineToPoint:
                guard let _currentPoint = currentPoint else { return }
                let endPoint = element.pointee.points[0]
                segments.append(.line(startPoint: _currentPoint, endPoint: endPoint))
                currentPoint = endPoint

            case .addQuadCurveToPoint:
                guard let _currentPoint = currentPoint else { return }
                let control = element.pointee.points[0]
                let endPoint = element.pointee.points[1]
                segments.append(
                    .quad(
                        startPoint: _currentPoint,
                        control: control,
                        endPoint: endPoint
                    )
                )
                currentPoint = endPoint

            case .addCurveToPoint:
                guard let _currentPoint = currentPoint else { return }
                let control1 = element.pointee.points[0]
                let control2 = element.pointee.points[1]
                let endPoint = element.pointee.points[2]
                segments.append(
                    .cubic(
                        startPoint: _currentPoint,
                        control1: control1,
                        control2: control2,
                        endPoint: endPoint
                    )
                )
                currentPoint = endPoint

            case .closeSubpath:
                guard let startPoint, let _currentPoint = currentPoint else { return }
                if abs(_currentPoint.x - startPoint.x) > 1e-4 || abs(_currentPoint.y - startPoint.y) > 1e-4 {
                    segments.append(.line(startPoint: _currentPoint, endPoint: startPoint))
                }
                currentPoint = startPoint
                isClosed = true

            @unknown default:
                break
            }
        }

        flushCurrentSubpath()
        return subpaths
    }
}

private enum PathSegment {
    case line(startPoint: CGPoint, endPoint: CGPoint)
    case quad(startPoint: CGPoint, control: CGPoint, endPoint: CGPoint)
    case cubic(startPoint: CGPoint, control1: CGPoint, control2: CGPoint, endPoint: CGPoint)

    var endPoint: CGPoint {
        switch self {
        case .line(_, let endPoint),
             .quad(_, _, let endPoint),
             .cubic(_, _, _, let endPoint):
            return endPoint
        }
    }

    func reversed() -> PathSegment {
        switch self {
        case .line(let startPoint, let endPoint):
            return .line(startPoint: endPoint, endPoint: startPoint)

        case .quad(let startPoint, let control, let endPoint):
            return .quad(startPoint: endPoint, control: control, endPoint: startPoint)

        case .cubic(let startPoint, let control1, let control2, let endPoint):
            return .cubic(
                startPoint: endPoint,
                control1: control2,
                control2: control1,
                endPoint: startPoint
            )
        }
    }

    func append(to path: inout Path) {
        switch self {
        case .line(_, let endPoint):
            path.addLine(to: endPoint)

        case .quad(_, let control, let endPoint):
            path.addQuadCurve(to: endPoint, control: control)

        case .cubic(_, let control1, let control2, let endPoint):
            path.addCurve(to: endPoint, control1: control1, control2: control2)
        }
    }
}

private struct ReversedPathMetadata {
    private(set) var endPoint: CGPoint = .zero
    private(set) var endTangentAngle: CGFloat?

    private var currentPoint: CGPoint = .zero
    private var subpathStart: CGPoint = .zero

    init(cgPath: CGPath) {
        cgPath.applyWithBlock { element in
            consume(element.pointee)
        }
    }

    private mutating func consume(_ element: CGPathElement) {
        switch element.type {
        case .moveToPoint:
            let point = element.points[0]
            currentPoint = point
            subpathStart = point

        case .addLineToPoint:
            let point = element.points[0]
            updateTangent(from: currentPoint, to: point)
            currentPoint = point

        case .addQuadCurveToPoint:
            let control = element.points[0]
            let end = element.points[1]
            if !updateTangent(from: control, to: end) {
                updateTangent(from: currentPoint, to: end)
            }
            currentPoint = end

        case .addCurveToPoint:
            let control1 = element.points[0]
            let control2 = element.points[1]
            let end = element.points[2]
            if !updateTangent(from: control2, to: end) {
                if !updateTangent(from: control1, to: end) {
                    updateTangent(from: currentPoint, to: end)
                }
            }
            currentPoint = end

        case .closeSubpath:
            updateTangent(from: currentPoint, to: subpathStart)
            currentPoint = subpathStart

        @unknown default:
            break
        }

        endPoint = currentPoint
    }

    @discardableResult
    private mutating func updateTangent(from start: CGPoint, to end: CGPoint) -> Bool {
        guard let angle = start.tangentAngle(to: end) else { return false }
        endTangentAngle = angle
        return true
    }
}
