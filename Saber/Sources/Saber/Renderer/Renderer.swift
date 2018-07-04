//
//  Renderer.swift
//  Saber
//
//  Created by andrey.pleshkov on 28/06/2018.
//

import Foundation

public class Renderer {

    private let data: ContainerData

    private let config: SaberConfiguration

    public init(data: ContainerData, config: SaberConfiguration) {
        self.data = data
        self.config = config
    }
}

extension Renderer {

    public func render() -> String {
        var out: [String] = []
        if let header = config.header {
            out.append(header)
            out.append("")
        }
        if data.imports.count > 0 {
            render(imports: data.imports, to: &out)
            out.append("")
        }
        render(name: data.name, inheritedFrom: data.inheritedFrom, to: &out)
        if data.storedProperties.count > 0 {
            out.append("")
            render(nested: data.storedProperties, to: &out)
        } else {
            out.append("")
        }
        render(initializer: data.initializer, to: &out)
        out.append("")
        for nested in [data.getters, data.makers, data.injectors] {
            guard nested.count > 0 else {
                continue
            }
            render(nested: nested, to: &out)
        }
        out.append("}")
        return out.joined(separator: "\n")
    }
}

extension Renderer {

    private func render(imports: [String], to out: inout [String]) {
        imports.forEach {
            out.append("import \($0)")
        }
    }

    private func render(name: String, inheritedFrom: [String], to out: inout [String]) {
        var line = "\(config.accessLevel) class \(name)"
        if inheritedFrom.count > 0 {
            line += ": "
            line += inheritedFrom.joined(separator: ", ")
        }
        line += " {"
        out.append(line)
    }

    private func render(nested: [[String]], to out: inout [String]) {
        nested.forEach { (block) in
            block.forEach { (line) in
                out.append("\(config.indent)\(line)")
            }
            out.append("")
        }
    }

    private func render(initializer: ContainerData.Initializer, to out: inout [String]) {
        out.append(
            {
                var str = "\(config.indent)\(config.accessLevel) init("
                str += initializer.args
                    .map { "\($0.name): \($0.typeName)" }
                    .joined(separator: ", ")
                str += ") {"
                return str
            }()
        )
        for nested in [initializer.creations, initializer.storedProperties] {
            guard nested.count > 0 else {
                continue
            }
            nested.forEach {
                out.append("\(config.indent)\(config.indent)\($0)")
            }
        }
        out.append("\(config.indent)}")
    }
}
