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

        static func create(inputPath: String) -> (_ outDir: String) -> (_ rawConfig: String) -> Options {
            return { (outPath) in
                return { (rawConfig) in
                    self.init(
                        inputDir: URL(fileURLWithPath: inputPath),
                        outDir: URL(fileURLWithPath: outPath),
                        rawConfig: rawConfig
                    )
                }
            }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "from", defaultValue: "", usage: "Directory with sources")
                <*> m <| Option(key: "out", defaultValue: "", usage: "Output directory")
                <*> m <| Option(key: "config", defaultValue: "", usage: "Path to *.yml or YAML text")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            let factory = ParsedDataFactory()
            try DirectoryTraverser.traverse(options.inputDir.absoluteString) { (p) in
                guard p.extension == "swift" else {
                    return
                }
                let parser = try FileParser(path: p.asString)
                try parser.parse(to: factory)
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
