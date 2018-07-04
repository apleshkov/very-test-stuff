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

    private let config: SaberConfiguration

    init(config: SaberConfiguration) {
        self.config = config
    }

    struct Options: OptionsProtocol {

        let path: String

        let outPath: String

        static func create(path: String) -> (_ outPath: String) -> Options {
            return { (outPath) in
                return self.init(path: path, outPath: outPath)
            }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "path", defaultValue: "", usage: "Directory with sources")
                <*> m <| Option(key: "out", defaultValue: "", usage: "Output directory")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        do {
            let factory = ParsedDataFactory()
            try DirectoryTraverser.traverse(options.path) { (p) in
                guard p.extension == "swift" else {
                    return
                }
                let parser = try FileParser(path: p.asString, moduleName: nil)
                try parser.parse(to: factory)
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
