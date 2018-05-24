//
//  AnnotationParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 24/05/2018.
//

import Foundation

// https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/LexicalStructure.html#//apple_ref/swift/grammar/line-break
private let newlinesCharacterSet = CharacterSet(charactersIn: "\u{000A}\u{000D}")

class AnnotationParser {

    private let prefix: String

    init(prefix: String = "@saber.") {
        self.prefix = prefix
    }

    func parse(contents: String) -> [AnnotatedLine] {
        return contents.components(separatedBy: newlinesCharacterSet).compactMap {
            let rawText = $0.trimmingCharacters(in: .whitespaces)
            guard let extractedText = extract(from: rawText) else {
                return nil
            }
            return nil
        }
    }

    func extract(from rawText: String) -> String? {
        guard rawText.hasPrefix("//") else {
            return nil
        }
        guard let prefixRange = rawText.range(of: prefix) else {
            return nil
        }
        let extracted = rawText[prefixRange.upperBound...]
        guard extracted.count > 0 else {
            return nil
        }
        return String(extracted)
    }
}

struct AnnotatedLine {

    var text: String
}
