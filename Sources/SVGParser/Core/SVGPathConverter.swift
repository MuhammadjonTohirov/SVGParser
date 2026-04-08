//
//  SVGPathConverter.swift
//  SVGParser
//
//  Created by applebro on 18/12/25.
//

import SwiftUI

/// Main Facade for the SVGParser package.
/// Converts SVG strings and files into SwiftUI Path and Shape objects.
public enum SVGPathConverter {
    
    // MARK: - Public API
    
    /// Convert SVG string to array of SwiftUI Paths
    public static func pathsFromSVGString(_ svgString: String) throws -> [PathDataParser.ParsedPath] {
        guard !svgString.isEmpty else {
            throw SVGError.invalidSVGString
        }

        let elements = try SVGElementExtractor.extractAllElements(from: svgString)

        return try elements.map { element in
            var parsed = try PathDataParser.parse(element.pathData)
            parsed.isFilled = element.isFilled
            return parsed
        }
    }
    
    /// Convert SVG string directly to SwiftUI Path (first path only)
    public static func pathFromSVGString(_ svgString: String) throws -> PathDataParser.ParsedPath {
        let paths = try pathsFromSVGString(svgString)
        guard let firstPath = paths.first else {
            throw SVGError.noPathDataFound
        }
        return firstPath
    }
    
    /// Convert SVG file to array of SwiftUI Paths
    public static func pathsFromSVGFile(_ fileName: String, bundle: Bundle = .main) throws -> [PathDataParser.ParsedPath] {
        let svgString = try SVGLoader.loadSVGFromFile(fileName, bundle: bundle)
        return try pathsFromSVGString(svgString)
    }

    /// Convert SVG file to SwiftUI Path (first path only)
    public static func pathFromSVGFile(_ fileName: String, bundle: Bundle = .main) throws -> PathDataParser.ParsedPath {
        let svgString = try SVGLoader.loadSVGFromFile(fileName, bundle: bundle)
        return try pathFromSVGString(svgString)
    }
    
    /// Convert SVG path data string directly to SwiftUI Path
    public static func pathFromPathData(_ pathData: String) throws -> PathDataParser.ParsedPath {
        return try PathDataParser.parse(pathData)
    }
    
    // MARK: - Shape Helpers
    
    /// Create multiple SwiftUI Shapes from SVG string
    public static func shapesFromSVGString(_ svgString: String) throws -> [SVGShape] {
        let paths = try pathsFromSVGString(svgString)
        return paths.map { SVGShape(parsed: $0) }
    }
    
    /// Create multiple SwiftUI Shapes from SVG file
    public static func shapesFromSVGFile(_ fileName: String, bundle: Bundle = .main) throws -> [SVGShape] {
        let paths = try pathsFromSVGFile(fileName, bundle: bundle)
        return paths.map { SVGShape(parsed: $0) }
    }
    
    /// Create a SwiftUI Shape from SVG string (first path only)
    public static func shapeFromSVGString(_ svgString: String) throws -> SVGShape {
        let path = try pathFromSVGString(svgString)
        return SVGShape(parsed: path)
    }
    
    /// Create a SwiftUI Shape from SVG file (first path only)
    public static func shapeFromSVGFile(_ fileName: String, bundle: Bundle = .main) throws -> SVGShape {
        let path = try pathFromSVGFile(fileName, bundle: bundle)
        return SVGShape(parsed: path)
    }
    
    /// Create a multi-path shape from SVG string
    public static func multiPathShapeFromSVGString(_ svgString: String) throws -> SVGMultiPathShape {
        let paths = try pathsFromSVGString(svgString)
        return SVGMultiPathShape(parsedPaths: paths)
    }
    
    /// Create a multi-path shape from SVG file
    public static func multiPathShapeFromSVGFile(_ fileName: String, bundle: Bundle = .main) throws -> SVGMultiPathShape {
        let paths = try pathsFromSVGFile(fileName, bundle: bundle)
        return SVGMultiPathShape(parsedPaths: paths)
    }
    
}

// MARK: - Convenience Extensions

public extension SVGPathConverter {
    
    static func multiPathsFromSVGFiles(_ fileNames: [String]) -> [String: [Path]] {
        var results: [String: [Path]] = [:]
        
        for fileName in fileNames {
            do {
                let paths = try pathsFromSVGFile(fileName)
                results[fileName] = paths.map(\.path)
            } catch {
                debugPrint("Failed to convert SVG file \(fileName): \(error.localizedDescription)")
            }
        }
        
        return results
    }
    
    static func pathsFromSVGFiles(_ fileNames: [String]) -> [String: Path] {
        var results: [String: Path] = [:]
        
        for fileName in fileNames {
            do {
                let path = try pathFromSVGFile(fileName)
                results[fileName] = path.path
            } catch {
                debugPrint("Failed to convert SVG file \(fileName): \(error.localizedDescription)")
            }
        }
        
        return results
    }
    
    static func isValidSVG(_ svgString: String) -> Bool {
        do {
            _ = try pathsFromSVGString(svgString)
            return true
        } catch {
            return false
        }
    }
}
