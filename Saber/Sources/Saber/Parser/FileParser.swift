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

    private let rawData: RawData

    private let moduleName: String?

    init(file: File, moduleName: String? = nil) throws {
        self.structure = try Structure(file: file).dictionary
        self.rawData = RawData(contents: file.contents)
        self.moduleName = moduleName
    }

    func parse(to data: ParsedDataFactory) throws {
        try parse(structure, to: data)
    }
    
    private func parse(_ structure: [String : SourceKitRepresentable], to data: ParsedDataFactory) throws {
        if var container = ContainerParser.parse(structure, rawData: rawData) {
            container.moduleName = moduleName
            try data.register(container)
        } else if let type = TypeParser.parse(structure, rawData: rawData) {
            process(type, parent: nil, data: data)
        } else if let ext = ExtensionParser.parse(structure, rawData: rawData) {
            process(ext, parent: nil, data: data)
        } else if let alias = TypealiasParser.parse(structure, rawData: rawData) {
            process(alias, parent: nil, data: data)
        } else {
            try structure.swiftSubstructures?.forEach {
                try parse($0, to: data)
            }
        }
    }

    private func process(_ type: ParsedType, parent: NestedParsedDecl?, data: ParsedDataFactory) {
        var type = type
        type.moduleName = moduleName
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
            case .typealias(let alias):
                process(alias, parent: .type(type), data: data)
            }
        }
    }

    private func process(_ ext: ParsedExtension, parent: NestedParsedDecl?, data: ParsedDataFactory) {
        var ext = ext
        ext.moduleName = moduleName
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
            case .typealias(let alias):
                process(alias, parent: .extension(ext), data: data)
            }
        }
    }

    private func process(_ alias: ParsedTypealias, parent: NestedParsedDecl?, data: ParsedDataFactory) {
        var alias = alias
        alias.moduleName = moduleName
        if let parentName = parent?.name {
            alias.name = "\(parentName).\(alias.name)"
        }
        data.register(alias)
    }
}
