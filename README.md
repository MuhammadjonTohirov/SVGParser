# SVGParser

A lightweight, pure Swift package for parsing SVG files and strings into SwiftUI `Path` and `Shape` objects.

## Features

- **SwiftUI Native**: Converts SVGs directly into `Path`, `Shape`, and `View` objects ready for SwiftUI.
- **Full SVG Path Spec**: Supports all SVG path commands including cubic/quadratic bezier curves, elliptical arcs, and smooth continuations.
- **Multi-Path Support**: Correctly parses complex SVGs with multiple elements and preserves individual path layers.
- **Path Reversal**: Reverse any parsed path direction while preserving geometry, useful for animations and text-on-path.
- **Component Model**: `SVGComponent` groups related paths (e.g., letter forms with dots/diacritics) with reactive reversal.
- **Built-in Viewer**: `SVGViewer` provides automatic viewBox-aware scaling with fill/stroke rendering and fallback text.
- **Batch Loading**: Load multiple SVG files at once with dictionary-based results.
- **SVG Validation**: Validate SVG strings without throwing.
- **No Dependencies**: Pure Swift implementation with zero third-party dependencies.

## Requirements

- iOS 16.6+
- Swift 6.2+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/aspect-suspended/SVGParser.git", from: "1.0.0")
]
```

Then add `SVGParser` to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SVGParser"]
)
```

## Usage

### Basic Shape from File

```swift
import SwiftUI
import SVGParser

struct ContentView: View {
    var body: some View {
        if let shape = try? SVGPathConverter.shapeFromSVGFile("icon_name") {
            shape
                .fill(Color.blue)
                .frame(width: 100, height: 100)
        }
    }
}
```

### Parse SVG String

```swift
let svgString = "<svg><path d=\"M10 10 L90 90\"/></svg>"
let shape = try SVGPathConverter.shapeFromSVGString(svgString)
```

### Parse Raw Path Data

```swift
let parsed = try SVGPathConverter.pathFromPathData("M0 0 C20 20, 40 20, 50 10")
// parsed.path      – SwiftUI Path
// parsed.endPoint  – final coordinate
// parsed.endTangentAngle – tangent angle at the endpoint (radians)
```

### Multi-Path Shapes

```swift
// All paths combined into a single shape
let multiShape = try SVGPathConverter.multiPathShapeFromSVGFile("layered_icon")

// Access individual paths
let individualPaths = multiShape.individualPaths
```

### Multiple Shapes with Individual Styling

```swift
let shapes = try SVGPathConverter.shapesFromSVGFile("complex_icon")

ZStack {
    ForEach(shapes.indices, id: \.self) { i in
        shapes[i].fill(colors[i])
    }
}
```

### SVGViewer (Auto-Scaling View)

```swift
SVGViewer(
    svgFileName: "letter_alif",
    fallbackText: "ا",
    strokeColor: .primary,
    strokeLineWidth: 3,
    contentInset: 8,
    bundle: .main
)
.frame(width: 200, height: 200)
```

`SVGViewer` automatically fits all paths into the available space, renders filled shapes as fills and open paths as strokes, and falls back to text if the file is not found.

### SVGComponent (Multi-Part Letters)

```swift
let component = try SVGPathConverter.pathComponentFromSVGString(svgString)

component.mainForm            // Primary path (e.g., letter body)
component.dotsAndDiacritics   // Secondary paths (e.g., dots)
component.count               // Total path count

// Reverse all paths reactively
var reversed = component
reversed.isReversed = true
```

### Batch Loading

```swift
// Load multiple files, returns [String: Path]
let paths = SVGPathConverter.pathsFromSVGFiles(["icon_a", "icon_b", "icon_c"])

// Load multiple files with all paths, returns [String: [Path]]
let multiPaths = SVGPathConverter.multiPathsFromSVGFiles(["shape_1", "shape_2"])
```

### Validation

```swift
if SVGPathConverter.isValidSVG(svgString) {
    // Safe to parse
}
```

## Supported SVG Elements

| Element      | Attributes                     | Rendering  |
|-------------|-------------------------------|------------|
| `<path>`    | `d`                           | Stroke     |
| `<circle>`  | `cx`, `cy`, `r`              | Fill       |
| `<rect>`    | `x`, `y`, `width`, `height`  | Fill       |
| `<ellipse>` | `cx`, `cy`, `rx`, `ry`       | Fill       |
| `<line>`    | `x1`, `y1`, `x2`, `y2`      | Stroke     |
| `<polygon>` | `points`                      | Fill       |
| `<polyline>`| `points`                      | Stroke     |

## Supported Path Commands

| Command | Name                    | Absolute/Relative |
|---------|------------------------|-------------------|
| `M/m`   | Move To                | Both              |
| `L/l`   | Line To                | Both              |
| `H/h`   | Horizontal Line        | Both              |
| `V/v`   | Vertical Line          | Both              |
| `C/c`   | Cubic Bezier           | Both              |
| `S/s`   | Smooth Cubic Bezier    | Both              |
| `Q/q`   | Quadratic Bezier       | Both              |
| `T/t`   | Smooth Quadratic Bezier| Both              |
| `A/a`   | Elliptical Arc         | Both              |
| `Z/z`   | Close Path             | Both              |

Additional parsing features:
- Implicit command repetition per SVG spec
- Implicit lineto after moveto
- Scientific notation (e.g., `1e-4`)
- Negative sign as implicit separator
- Reflected control points for `S` and `T` commands

## Error Handling

`SVGError` provides typed errors conforming to `LocalizedError`:

```swift
do {
    let shape = try SVGPathConverter.shapeFromSVGFile("missing")
} catch let error as SVGError {
    switch error {
    case .invalidSVGString:  // Invalid SVG string provided
    case .fileNotFound:      // SVG file not found in bundle
    case .parsingFailed:     // Failed to parse SVG data
    case .noPathDataFound:   // No valid path data found in SVG
    case .invalidPathData:   // Invalid path data format
    }
}
```

## Architecture

```
SVGParser/
├── Core/
│   └── SVGPathConverter        — Main facade (static API)
├── Parsers/
│   ├── SVGElementExtractor     — Regex-based SVG element extraction
│   ├── PathTokenizer           — Tokenizes path data strings
│   ├── PathDataParser          — Builds SwiftUI Path from tokens
│   ├── PathBuilderState        — Stateful path construction
│   ├── SVGArcConverter         — Elliptical arc to cubic bezier
│   └── ParsedPath+Reversed     — Path direction reversal
├── Converters/
│   └── ShapeToPathConverter    — Circle, rect, ellipse, etc. to path data
├── Models/
│   ├── SVGShape                — Single-path SwiftUI Shape
│   ├── SVGMultiPathShape       — Multi-path SwiftUI Shape
│   └── SVGComponent            — Multi-part component container
├── Views/
│   └── SVGViewer               — Auto-scaling SwiftUI View
├── Extensions/
│   └── CGPoint+SVG             — Geometry helpers (adding, reflection, tangent)
└── Loaders/
    └── SVGLoader               — Bundle resource file loading
```

**Parsing Pipeline:**

1. **Load** — `SVGLoader` reads the `.svg` file from the app bundle
2. **Extract** — `SVGElementExtractor` finds all SVG elements via regex and converts shapes to path data strings
3. **Tokenize** — `PathTokenizer` splits path data into command and number tokens
4. **Parse** — `PathDataParser` walks tokens through `PathBuilderState` to build a SwiftUI `Path`
5. **Wrap** — Results are wrapped in `SVGShape`, `SVGMultiPathShape`, or `SVGComponent` for SwiftUI use

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
