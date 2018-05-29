//
//  FileParser.swift
//  Parser
//
//  Created by andrey.pleshkov on 23/05/2018.
//

import Foundation
import SourceKittenFramework

class FileParser {

    private let structure: [String : SourceKitRepresentable]

    private let rawAnnotations: RawAnnotations

    private let moduleName: String?

    init(file: File, moduleName: String? = nil) throws {
        self.structure = try Structure(file: file).dictionary
        self.rawAnnotations = RawAnnotations(contents: file.contents)
        self.moduleName = moduleName
    }

    func parse(to data: ParsedDataFactory) {
        parse(structure, to: data)
    }
    
    private func parse(_ structure: [String : SourceKitRepresentable], to data: ParsedDataFactory) {
        if let type = TypeParser.parse(structure, rawAnnotations: rawAnnotations) {
            process(type, parent: nil, data: data)
        } else if let ext = ExtensionParser.parse(structure, rawAnnotations: rawAnnotations) {
            process(ext, parent: nil, data: data)
        } else {
            structure.swiftSubstructures?.forEach {
                parse($0, to: data)
            }
        }
    }

    private func process(_ type: ParsedType, parent: NestedParsedDecl?, data: ParsedDataFactory) {
        var type = type
        if let parentName = parent?.name {
            type.name = "\(parentName).\(type.name)"
        }
        data.register(type)
        type.nested.forEach {
            switch $0 {
            case .type(let nestedType):
                process(nestedType, parent: .type(type), data: data)
            case .extension(let nestedExt):
                process(nestedExt, parent: .type(type), data: data)
            }
        }
    }

    private func process(_ ext: ParsedExtension, parent: NestedParsedDecl?, data: ParsedDataFactory) {
        var ext = ext
        if let parentName = parent?.name {
            ext.typeName = "\(parentName).\(ext.typeName)"
        }
        data.register(ext)
        ext.nested.forEach {
            switch $0 {
            case .type(let nestedType):
                process(nestedType, parent: .extension(ext), data: data)
            case .extension(let nestedExt):
                process(nestedExt, parent: .extension(ext), data: data)
            }
        }
    }
}
