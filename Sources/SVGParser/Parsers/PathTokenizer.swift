//
//  PathTokenizer.swift
//  SVGParser
//
//  Created by applebro on 17/03/26.
//

import Foundation

/// Token produced by the SVG path data tokenizer.
enum PathToken {
    case command(Character)
    case number(CGFloat)
}

/// Splits an SVG path data string into a sequence of `PathToken` values.
///
/// Handles edge cases per SVG spec:
/// - Negative sign as implicit separator: `10-20` → `10`, `-20`
/// - Consecutive decimal points: `.5.3` → `0.5`, `0.3`
/// - Scientific notation: `1e-4`
enum PathTokenizer {

    static func tokenize(_ data: String) -> [PathToken] {
        var tokens: [PathToken] = []
        var buffer = ""
        var hasDecimal = false

        func flush() {
            guard !buffer.isEmpty, let value = Double(buffer) else {
                buffer = ""
                hasDecimal = false
                return
            }
            tokens.append(.number(CGFloat(value)))
            buffer = ""
            hasDecimal = false
        }

        for char in data {
            switch char {
            case "M", "m", "L", "l", "H", "h", "V", "v",
                 "C", "c", "S", "s", "Q", "q", "T", "t",
                 "A", "a", "Z", "z":
                flush()
                tokens.append(.command(char))

            case "-":
                if !buffer.isEmpty { flush() }
                buffer = "-"

            case ".":
                if hasDecimal { flush() }
                if buffer.isEmpty { buffer = "0" }
                buffer.append(".")
                hasDecimal = true

            case "0"..."9":
                buffer.append(char)

            case "e", "E":
                buffer.append(char)

            case "+":
                if buffer.hasSuffix("e") || buffer.hasSuffix("E") {
                    buffer.append(char)
                } else {
                    flush()
                }

            default:
                // Whitespace, commas, and other separators
                flush()
            }
        }

        flush()
        return tokens
    }
}
