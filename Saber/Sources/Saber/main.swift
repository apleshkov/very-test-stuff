//
//  main.swift
//  Saber
//
//  Created by Andrew Pleshkov on 02/07/2018.
//

import Foundation
import Commandant

let commands = CommandRegistry<Throwable>()
commands.register(GenerateXcodeProjectCommand())

var args = CommandLine.arguments.dropFirst()

guard let action = args.first else {
    print("No action given")
    exit(0)
}

args = args.dropFirst()
guard let result = commands.run(command: action, arguments: Array(args)) else {
    print("Unrecognized action: '\(action)'")
    exit(1)
}

switch result {
case .success(_):
    break
case .failure(let error):
    print(error.localizedDescription)
    exit(1)
}
