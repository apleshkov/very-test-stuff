//
//  GenerateXcodeProjectCommand.swift
//  Saber
//
//  Created by andrey.pleshkov on 02/07/2018.
//

import Foundation
import Commandant
import Result

struct GenerateXcodeProjectCommand: CommandProtocol {

    let verb = "xcodeproj"
    let function = "Generate containers from Xcode project"

    struct Options: OptionsProtocol {

        let path: String
        
        let targetNames: Set<String>

        static func create(path: String) -> (_ rawTargets: String) -> Options {
            return { (rawTargets) in
                let array = rawTargets
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                let targetNames = Set(array)
                return self.init(path: path, targetNames: targetNames)
            }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "path", defaultValue: "", usage: "Path to *.xcodeproj")
                <*> m <| Option(key: "targets", defaultValue: "", usage: "Comma-separated list of target names")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            guard options.targetNames.count > 0 else {
                return .failure(Throwable.message("No target found"))
            }
            let project = try SaberXProject(path: options.path, targetNames: options.targetNames)
            let factory = ParsedDataFactory()
            try project.targets.forEach { (target) in
                try target.filePaths.forEach { (path) in
                    let parser = try FileParser(path: path, moduleName: target.name)
                    try parser.parse(to: factory)
                }
            }
            let containers = try ContainerFactory(repo: TypeRepository(parsedData: factory.make())).make()
            print(containers)
            return .success(())
        } catch {
            return .failure(Throwable.message(error.localizedDescription))
        }
    }
}
