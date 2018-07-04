//
//  XcodeProjectCommand.swift
//  Saber
//
//  Created by andrey.pleshkov on 02/07/2018.
//

import Foundation
import Saber
import Commandant
import Result

struct XcodeProjectCommand: CommandProtocol {

    let verb = "xcodeproj"
    let function = "Generate containers from Xcode project"

    private let config: SaberConfiguration

    init(config: SaberConfiguration) {
        self.config = config
    }

    struct Options: OptionsProtocol {

        let path: String
        
        let targetNames: Set<String>

        let outPath: String

        static func create(path: String) -> (_ rawTargets: String) -> (_ outPath: String) -> Options {
            return { (rawTargets) in
                let array = rawTargets
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                let targetNames = Set(array)
                return { (outPath) in
                    return self.init(path: path, targetNames: targetNames, outPath: outPath)
                }
            }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "path", defaultValue: "", usage: "Path to *.xcodeproj")
                <*> m <| Option(key: "targets", defaultValue: "", usage: "Comma-separated list of target names")
                <*> m <| Option(key: "out", defaultValue: "", usage: "Output directory")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            guard options.targetNames.count > 0 else {
                throw Throwable.message("No targets found")
            }
            let project = try SaberXProject(path: options.path, targetNames: options.targetNames)
            let factory = ParsedDataFactory()
            try project.targets.forEach { (target) in
                try target.filePaths.forEach { (path) in
                    let parser = try FileParser(path: path, moduleName: target.name)
                    try parser.parse(to: factory)
                }
            }
            let containers = try ContainerFactory.make(from: factory)
            guard containers.count > 0 else {
                throw Throwable.message("No containers found")
            }
            try FileRenderer(pathString: options.outPath, config: config).render(containers: containers)
            print("Generated")
            return .success(())
        } catch {
            return .failure(.wrapped(error))
        }
    }
}
