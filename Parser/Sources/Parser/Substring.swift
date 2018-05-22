//
//  Substring.swift
//  CYaml
//
//  Created by Andrew Pleshkov on 22/05/2018.
//

import Foundation
import SourceKittenFramework

enum Substring {
    case key
    case name
    case fullName
    
    private func extract(from structure: [String : SourceKitRepresentable], offsetKey: SwiftDocKey, lengthKey: SwiftDocKey) -> Range<Int>? {
        guard let offset = structure[offsetKey] as? Int64 else {
            return nil
        }
        guard let length = structure[lengthKey] as? Int64 else {
            return nil
        }
        return Int(offset)..<Int(offset + length)
    }
    
    func range(for structure: [String : SourceKitRepresentable]) -> Range<Int>? {
        switch self {
        case .key:
            return extract(from: structure, offsetKey: .offset, lengthKey: .length)
        case .name:
            return extract(from: structure, offsetKey: .nameOffset, lengthKey: .nameLength)
        case .fullName:
            guard let nameRange = Substring.name.range(for: structure),
                let keyRange = Substring.key.range(for: structure) else {
                return nil
            }
            return nameRange.lowerBound..<keyRange.upperBound
        }
    }
    
    func extract(from structure: [String : SourceKitRepresentable], contents: String) -> String? {
        guard let intRange = range(for: structure) else {
            return nil
        }
        let startIndex = contents.index(contents.startIndex, offsetBy: intRange.lowerBound)
        let endIndex = contents.index(contents.startIndex, offsetBy: intRange.upperBound)
        return String(contents[startIndex..<endIndex])
    }
}
