//
//  SVGErrors.swift
//  SVGParser
//
//  Created by applebro on 18/12/25.
//

import Foundation

public enum SVGError: Error, LocalizedError {
    case invalidSVGString
    case fileNotFound
    case parsingFailed
    case noPathDataFound
    case invalidPathData
    
    public var errorDescription: String? {
        switch self {
        case .invalidSVGString:
            return "Invalid SVG string provided"
        case .fileNotFound:
            return "SVG file not found"
        case .parsingFailed:
            return "Failed to parse SVG data"
        case .noPathDataFound:
            return "No valid path data found in SVG"
        case .invalidPathData:
            return "Invalid path data format"
        }
    }
}
