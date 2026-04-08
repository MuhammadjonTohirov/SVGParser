//
//  SVGElementExtractor.swift
//  SVGParser
//
//  Created by applebro on 18/12/25.
//

import Foundation
import CoreGraphics

/// Extracted SVG element with path data and rendering info.
struct SVGExtractedElement {
    let pathData: String
    /// Closed shapes (circle, rect, ellipse, polygon) should be filled, not stroked.
    let isFilled: Bool
}

/// Responsible for extracting different SVG elements (path, circle, rect, etc.)
/// from the raw SVG string and converting them to uniform Path Data strings.
enum SVGElementExtractor {

    static func extractAllElements(from svgString: String) throws -> [SVGExtractedElement] {
        var elements: [SVGExtractedElement] = []

        elements.append(contentsOf: try extractPathElements(from: svgString).map { .init(pathData: $0, isFilled: false) })
        elements.append(contentsOf: try extractCircleElements(from: svgString).map { .init(pathData: $0, isFilled: true) })
        elements.append(contentsOf: try extractRectElements(from: svgString).map { .init(pathData: $0, isFilled: true) })
        elements.append(contentsOf: try extractEllipseElements(from: svgString).map { .init(pathData: $0, isFilled: true) })
        elements.append(contentsOf: try extractLineElements(from: svgString).map { .init(pathData: $0, isFilled: false) })
        elements.append(contentsOf: try extractPolygonElements(from: svgString).map { .init(pathData: $0, isFilled: true) })
        elements.append(contentsOf: try extractPolylineElements(from: svgString).map { .init(pathData: $0, isFilled: false) })

        guard !elements.isEmpty else {
            throw SVGError.noPathDataFound
        }

        return elements
    }

    // MARK: - Private Extractors

    private static func extractPathElements(from svgString: String) throws -> [String] {
        try extractMatches(from: svgString, pattern: #"<path[^>]*d=\"([^"]*)\""#, index: 1)
    }

    private static func extractCircleElements(from svgString: String) throws -> [String] {
        let pattern = #"<circle[^>]*cx=\"([^"]*)\"\s*[^>]*cy=\"([^"]*)\"\s*[^>]*r=\"([^"]*)""#
        return try extractNumericAttributes(from: svgString, pattern: pattern, count: 3) { values in
            ShapeToPathConverter.circleToPathData(cx: values[0], cy: values[1], r: values[2])
        }
    }

    private static func extractRectElements(from svgString: String) throws -> [String] {
        let pattern = #"<rect[^>]*x=\"([^"]*)\"\s*[^>]*y=\"([^"]*)\"\s*[^>]*width=\"([^"]*)\"\s*[^>]*height=\"([^"]*)""#
        return try extractNumericAttributes(from: svgString, pattern: pattern, count: 4) { values in
            ShapeToPathConverter.rectToPathData(x: values[0], y: values[1], width: values[2], height: values[3])
        }
    }

    private static func extractEllipseElements(from svgString: String) throws -> [String] {
        let pattern = #"<ellipse[^>]*cx=\"([^"]*)\"\s*[^>]*cy=\"([^"]*)\"\s*[^>]*rx=\"([^"]*)\"\s*[^>]*ry=\"([^"]*)""#
        return try extractNumericAttributes(from: svgString, pattern: pattern, count: 4) { values in
            ShapeToPathConverter.ellipseToPathData(cx: values[0], cy: values[1], rx: values[2], ry: values[3])
        }
    }

    private static func extractLineElements(from svgString: String) throws -> [String] {
        let pattern = #"<line[^>]*x1=\"([^"]*)\"\s*[^>]*y1=\"([^"]*)\"\s*[^>]*x2=\"([^"]*)\"\s*[^>]*y2=\"([^"]*)""#
        return try extractNumericAttributes(from: svgString, pattern: pattern, count: 4) { values in
            ShapeToPathConverter.lineToPathData(x1: values[0], y1: values[1], x2: values[2], y2: values[3])
        }
    }

    private static func extractPolygonElements(from svgString: String) throws -> [String] {
        try extractMatches(from: svgString, pattern: #"<polygon[^>]*points=\"([^"]*)\""#, index: 1) {
            ShapeToPathConverter.polygonToPathData(points: $0)
        }
    }

    private static func extractPolylineElements(from svgString: String) throws -> [String] {
        try extractMatches(from: svgString, pattern: #"<polyline[^>]*points=\"([^"]*)\""#, index: 1) {
            ShapeToPathConverter.polylineToPathData(points: $0)
        }
    }

    // MARK: - Helpers

    /// Extracts N numeric capture groups from regex matches and transforms them into path data.
    private static func extractNumericAttributes(
        from text: String,
        pattern: String,
        count: Int,
        transform: ([CGFloat]) -> String
    ) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        return matches.compactMap { match in
            var values: [CGFloat] = []
            for i in 1...count {
                guard let range = Range(match.range(at: i), in: text),
                      let value = Float(String(text[range])) else { return nil }
                values.append(CGFloat(value))
            }
            return transform(values)
        }
    }

    private static func extractMatches(
        from text: String,
        pattern: String,
        index: Int,
        transform: ((String) -> String)? = nil
    ) throws -> [String] {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        return matches.compactMap { match in
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            let captured = String(text[range])
            return transform?(captured) ?? captured
        }
    }
}
