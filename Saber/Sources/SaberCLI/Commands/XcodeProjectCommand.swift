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

    private let defaultConfig: SaberConfiguration

    init(config: SaberConfiguration) {
        self.defaultConfig = config
    }

    struct Options: OptionsProtocol {

        let url: URL
        
        let targetNames: Set<String>

        let outDir: URL

        let rawConfig: String

        static func create(path: String) -> (_ rawTargets: String) -> (_ outPath: String) -> (_ rawConfig: String) -> Options {
            let url = URL(fileURLWithPath: path)
            return { (rawTargets) in
                let array = rawTargets
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                let targetNames = Set(array)
                return { (outPath) in
                    let outDir = URL(fileURLWithPath: outPath)
                    return { (rawConfig) in
                        return self.init(url: url, targetNames: targetNames, outDir: outDir, rawConfig: rawConfig)
                    }
                }
            }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "path", defaultValue: "", usage: "Path to *.xcodeproj")
                <*> m <| Option(key: "targets", defaultValue: "", usage: "Comma-separated list of target names")
                <*> m <| Option(key: "out", defaultValue: "", usage: "Output directory")
                <*> m <| Option(key: "config", defaultValue: "", usage: "Path to *.yml or YAML text")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            guard options.targetNames.count > 0 else {
                throw Throwable.message("No targets found")
            }
            let project = try SaberXProject(path: options.url.absoluteString, targetNames: options.targetNames)
            let factory = ParsedDataFactory()
            try project.targets.forEach { (target) in
                try target.filePaths.forEach { (path) in
                    let parser = try FileParser(path: path, moduleName: target.name)
                    try parser.parse(to: factory)
                }
            }
            try FileRenderer.render(
                params: FileRenderer.Params(
                    parsedDataFactory: factory,
                    outDir: options.outDir,
                    rawConfig: options.rawConfig,
                    defaultConfig: defaultConfig
                )
            )
            print("Generated")
            return .success(())
        } catch {
            return .failure(.wrapped(error))
        }
    }
}
