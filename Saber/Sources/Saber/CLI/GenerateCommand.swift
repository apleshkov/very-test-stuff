//
//  GenerateCommand.swift
//  Saber
//
//  Created by andrey.pleshkov on 02/07/2018.
//

import Foundation
import Commandant
import Result

struct GenerateCommand: CommandProtocol {

    let verb = "generate"
    let function = "Generate containers"

    struct Options: OptionsProtocol {

        let xcodeproj: String

        static func create(xcodeproj: String) -> Options {
            return self.init(xcodeproj: xcodeproj)
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<Throwable>> {
            return create
                <*> m <| Option(key: "xcodeproj", defaultValue: "", usage: "Path to xcodeproj-file")
        }
    }

    func run(_ options: Options) -> Result<(), Throwable> {
        return .success(())
    }
}
