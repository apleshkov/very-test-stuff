//
//  TypeParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 21/05/2018.
//

import Foundation
import SourceKittenFramework

class TypeParser {

    func parse(_ rawString: String) -> ParsedType? {
        let rawString = rawString.trimmingCharacters(in: .whitespaces)
        guard rawString.count > 0 else {
            return nil
        }
        var isOptional = false
        var isUnwrapped = false
        var name = rawString
        if name.hasSuffix("?") {
            isOptional = true
            name = String(name.dropLast())
        } else if name.hasSuffix("!") {
            isUnwrapped = true
            name = String(name.dropLast())
        }
        var generics: [ParsedType] = []
        if let startIndex = name.index(of: "<"), let endIndex = name.index(of: ">") {
            let range = startIndex...endIndex
            generics = name[range.lowerBound..<range.upperBound]
                .dropFirst()
                .split(separator: ",")
                .compactMap { self.parse(String($0)) }
            name.removeSubrange(range)
        }
        var type = ParsedType(name: name)
        type.isOptional = isOptional
        type.isUnwrapped = isUnwrapped
        type.generics = generics
        return type
    }

    func parse(_ structure: [String : SourceKitRepresentable], contents: String) -> ParsedType? {
        guard let kind = structure.swiftDeclKind else {
            return nil
        }
        switch kind {
        case .struct, .class:
            guard let name = parseName(from: structure, contents: contents) else {
                return nil
            }
            let isReference = (kind == .class)
            return ParsedType(name: name, isReference: isReference)
        default:
            return nil
        }
    }

    private func parseName(from structure: [String : SourceKitRepresentable], contents: String) -> String? {
        func range(offsetKey: SwiftDocKey, lengthKey: SwiftDocKey) -> (offset: Int64, length: Int64)? {
            guard let offset = structure[offsetKey] as? Int64,
                let length = structure[lengthKey] as? Int64 else {
                    return nil
            }
            return (offset, length)
        }
        guard let nameRange = range(offsetKey: .nameOffset, lengthKey: .nameLength),
            let bodyRange = range(offsetKey: .bodyOffset, lengthKey: .bodyLength) else {
                return nil
        }
        let startIndex = nameRange.offset
        let endIndex = bodyRange.offset
        let xxx = substring(of: contents, with: startIndex..<endIndex)
//        let range = contents.index(contents.startIndex, offsetBy: startIndex)..<contents.index(contents.startIndex, offsetBy: endIndex)
//        let xxx = contents.substring(with: range)
//        return String(xxx)
        return nil
    }

    private func substring(of string: String, with range: Range<Int64>) -> String {
        let startIndex = string.index(string.startIndex, offsetBy: range.lowerBound)
        let endIndex = string.index(string.startIndex, offsetBy: range.upperBound)
        let strRange = startIndex..<endIndex
        return string.substring(with: strRange)
    }
}
