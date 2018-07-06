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

        static func create(workDir: String)
            -> (_ path: String)
            -> (_ rawTargets: String)
            -> (_ outPath: String)
            -> (_ rawConfig: String)
            -> Options {
                let baseURL: URL? = workDir.count > 0
                    ? URL(fileURLWithPath: workDir, isDirectory: true)
                    : nil
                return { (path) in                    
                    let url = URL(fileURLWithPath: path).saber_relative(to: baseURL)
                    return { (rawTargets) in
                        let array = rawTargets
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                        let targetNames = Set(array)
                        return { (outPath) in
                            let outDir = URL(fileURLWithPath: outPath).saber_relative(to: baseURL)
                            return { (rawConfig) in
                                return self.init(url: url, targetNames: targetNames, outDir: outDir, rawConfig: rawConfig)
                            }
                        }
                    }
                }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "workDir", defaultValue: "", usage: "Working directory (optional)")
                <*> m <| Option(key: "path", defaultValue: "", usage: "Path to *.xcodeproj (is relative to --workDir if any)")
                <*> m <| Option(key: "targets", defaultValue: "", usage: "Comma-separated list of project target names")
                <*> m <| Option(key: "out", defaultValue: "", usage: "Output directory (is relative to --workDir if any)")
                <*> m <| Option(key: "config", defaultValue: "", usage: "Path to *.yml or YAML text (optional)")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            guard options.targetNames.count > 0 else {
                throw Throwable.message("No targets found")
            }
            let project = try SaberXProject(path: options.url.path, targetNames: options.targetNames)
            let factory = ParsedDataFactory()
            try project.targets.forEach { (target) in
                try target.filePaths.forEach { (path) in
                    let parser = try FileParser(path: path, moduleName: target.name)
                    try parser.parse(to: factory)
                }
            }
            try FileRenderer.render(
                params: FileRenderer.Params(
                    version: saberVersion,
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
