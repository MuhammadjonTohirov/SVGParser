//
//  SVGViewer.swift
//  SVGParser
//
//  Created by applebro on 18/03/26.
//

import SwiftUI

public struct SVGViewer: View {
    public let svgFileName: String?
    public let fallbackText: String
    public let strokeColor: Color
    public let strokeLineWidth: CGFloat
    public let contentInset: CGFloat
    public let fallbackFont: Font
    public let bundle: Bundle

    private let parsedPaths: [PathDataParser.ParsedPath]

    public init(
        svgFileName: String?,
        fallbackText: String,
        strokeColor: Color,
        strokeLineWidth: CGFloat,
        contentInset: CGFloat = 0,
        fallbackFont: Font = .system(size: 17),
        bundle: Bundle = .main
    ) {
        self.svgFileName = svgFileName
        self.fallbackText = fallbackText
        self.strokeColor = strokeColor
        self.strokeLineWidth = strokeLineWidth
        self.contentInset = contentInset
        self.fallbackFont = fallbackFont
        self.bundle = bundle
        self.parsedPaths = Self.loadParsedPaths(named: svgFileName, bundle: bundle)
    }

    public var body: some View {
        GeometryReader { geometry in
            Group {
                if let transform = fittingTransform(in: geometry.size) {
                    ZStack {
                        ForEach(parsedPaths.indices, id: \.self) { index in
                            let parsed = parsedPaths[index]
                            let fitted = parsed.path.applying(transform)

                            if parsed.isFilled {
                                SVGShape(path: fitted)
                                    .fill(strokeColor)
                            } else {
                                SVGShape(path: fitted)
                                    .stroke(
                                        style: StrokeStyle(
                                            lineWidth: strokeLineWidth,
                                            lineCap: .round,
                                            lineJoin: .round
                                        )
                                    )
                                    .fill(strokeColor)
                            }
                        }
                    }
                } else {
                    Text(fallbackText)
                        .font(fallbackFont)
                        .foregroundStyle(strokeColor)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    /// Computes a single transform that fits all paths into the given size.
    private func fittingTransform(in size: CGSize) -> CGAffineTransform? {
        guard !parsedPaths.isEmpty else { return nil }

        var combinedPath = Path()
        for parsedPath in parsedPaths {
            combinedPath.addPath(parsedPath.path)
        }

        let bounds = combinedPath.boundingRect
        guard bounds.width > 0, bounds.height > 0 else { return .identity }

        let availableWidth = max(size.width - (contentInset * 2), 1)
        let availableHeight = max(size.height - (contentInset * 2), 1)
        let scale = min(availableWidth / bounds.width, availableHeight / bounds.height)

        let scaledWidth = bounds.width * scale
        let scaledHeight = bounds.height * scale
        let offsetX = (size.width - scaledWidth) / 2
        let offsetY = (size.height - scaledHeight) / 2

        // 1. Translate to origin → 2. Scale → 3. Center in available space
        let translateToOrigin = CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let centerTransform = CGAffineTransform(translationX: offsetX, y: offsetY)

        return translateToOrigin
            .concatenating(scaleTransform)
            .concatenating(centerTransform)
    }

    private static func loadParsedPaths(named fileName: String?, bundle: Bundle) -> [PathDataParser.ParsedPath] {
        guard let fileName,
              let parsedPaths = try? SVGPathConverter.pathsFromSVGFile(fileName, bundle: bundle) else {
            return []
        }

        return parsedPaths
    }
}
