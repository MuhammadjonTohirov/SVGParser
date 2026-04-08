import SwiftUI
import XCTest
@testable import SVGParser

final class SVGComponentTests: XCTestCase {
    func testReversingComponentFlipsPathDirection() throws {
        let parsedPath = try PathDataParser.parse("M0 0 L10 0")
        var component = SVGComponent(paths: [parsedPath])
        guard let originalPath = component.path(at: 0) else {
            return XCTFail("Expected original path")
        }

        XCTAssertEqual(component.count, 1)
        XCTAssertEqual(originalPath.endPoint.x, 10, accuracy: 0.001)
        XCTAssertEqual(originalPath.endPoint.y, 0, accuracy: 0.001)
        XCTAssertEqual(originalPath.endTangentAngle ?? 0, 0, accuracy: 0.001)
        XCTAssertEqual(firstPoint(in: originalPath.path.cgPath), CGPoint(x: 0, y: 0))

        component.isReversed = true

        guard let reversedPath = component.path(at: 0) else {
            return XCTFail("Expected reversed path")
        }

        XCTAssertEqual(firstPoint(in: reversedPath.path.cgPath), CGPoint(x: 10, y: 0))
        XCTAssertEqual(reversedPath.endPoint.x, 0, accuracy: 0.001)
        XCTAssertEqual(reversedPath.endPoint.y, 0, accuracy: 0.001)
        XCTAssertEqual(abs(normalized(reversedPath.endTangentAngle ?? 0)), .pi, accuracy: 0.001)
    }

    func testSVGPathConverterCreatesReversedComponentWhenRequested() throws {
        let svgString = """
        <svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0 L10 0" />
        </svg>
        """

        let component = try SVGPathConverter.pathComponentFromSVGString(svgString, isReversed: true)
        guard let parsedPath = component.path(at: 0) else {
            return XCTFail("Expected parsed path")
        }

        XCTAssertEqual(firstPoint(in: parsedPath.path.cgPath), CGPoint(x: 10, y: 0))
        XCTAssertEqual(parsedPath.endPoint.x, 0, accuracy: 0.001)
    }

    func testReversingClosedPathDoesNotInsertDegenerateLeadingLine() throws {
        let parsedPath = try PathDataParser.parse("M0 0 L10 0 L0 0 Z")
        let reversedPath = parsedPath.reversed()
        let elements = elementSnapshots(in: reversedPath.path.cgPath)

        XCTAssertEqual(elements.first?.type, .moveToPoint)
        XCTAssertEqual(elements.dropFirst().first?.type, .addLineToPoint)

        guard let firstLineEndPoint = elements.dropFirst().first?.points.first else {
            return XCTFail("Expected reversed path to contain a drawable first segment")
        }

        XCTAssertEqual(firstLineEndPoint.x, 10, accuracy: 0.001)
        XCTAssertEqual(firstLineEndPoint.y, 0, accuracy: 0.001)
    }

    private func firstPoint(in cgPath: CGPath?) -> CGPoint? {
        guard let cgPath else { return nil }

        var point: CGPoint?
        cgPath.applyWithBlock { element in
            guard point == nil else { return }
            if element.pointee.type == .moveToPoint {
                point = element.pointee.points[0]
            }
        }
        return point
    }

    private func normalized(_ angle: CGFloat) -> CGFloat {
        atan2(sin(angle), cos(angle))
    }

    private func elementSnapshots(in cgPath: CGPath) -> [(type: CGPathElementType, points: [CGPoint])] {
        var snapshots: [(type: CGPathElementType, points: [CGPoint])] = []

        cgPath.applyWithBlock { element in
            let element = element.pointee
            let pointCount: Int

            switch element.type {
            case .moveToPoint, .addLineToPoint:
                pointCount = 1
            case .addQuadCurveToPoint:
                pointCount = 2
            case .addCurveToPoint:
                pointCount = 3
            case .closeSubpath:
                pointCount = 0
            @unknown default:
                pointCount = 0
            }

            let points = (0..<pointCount).map { element.points[$0] }
            snapshots.append((type: element.type, points: points))
        }

        return snapshots
    }
}
