//
//  SourcesCommand.swift
//  SaberCLI
//
//  Created by andrey.pleshkov on 04/07/2018.
//

import Foundation
import Saber
import Commandant
import Result

struct SourcesCommand: CommandProtocol {

    let verb = "sources"
    let function = "Generate containers from sources"

    private let defaultConfig: SaberConfiguration

    init(config: SaberConfiguration) {
        self.defaultConfig = config
    }

    struct Options: OptionsProtocol {

        let inputDir: URL

        let outDir: URL

        let rawConfig: String

        static func create(workDir: String)
            -> (_ inputPath: String)
            -> (_ outDir: String)
            -> (_ rawConfig: String)
            -> Options {
                let baseURL: URL? = workDir.count > 0
                    ? URL(fileURLWithPath: workDir, isDirectory: true)
                    : nil
                return { (inputPath) in
                    let inputDir = URL(fileURLWithPath: inputPath).saber_relative(to: baseURL)
                    return { (outPath) in
                        let outDir = URL(fileURLWithPath: outPath).saber_relative(to: baseURL)
                        return { (rawConfig) in
                            self.init(
                                inputDir: inputDir,
                                outDir: outDir,
                                rawConfig: rawConfig
                            )
                        }
                    }
                }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "workDir", defaultValue: "", usage: "Working directory (optional)")
                <*> m <| Option(key: "from", defaultValue: "", usage: "Directory with sources (is relative to --workDir if any)")
                <*> m <| Option(key: "out", defaultValue: "", usage: "Output directory (is relative to --workDir if any)")
                <*> m <| Option(key: "config", defaultValue: "", usage: "Path to *.yml or YAML text (optional)")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            let factory = ParsedDataFactory()
            try DirectoryTraverser.traverse(options.inputDir.path) { (p) in
                guard p.extension == "swift" else {
                    return
                }
                let parser = try FileParser(path: p.asString)
                Logger?.info("Parsing \(p.asString)...")
                try parser.parse(to: factory)
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
