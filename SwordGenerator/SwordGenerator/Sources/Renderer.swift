//
//  Renderer.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 01/05/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

private let indent = "    "

class Renderer {
    
    func render(_ data: ContainerData) {
        print("class \(data.name) {")
        
        print()
        data.properties.forEach {
            print("\(indent)\($0.declaration)")
        }
        
        print()
        let initArgs = data.initializer.args.map {
            return "\($0.name): \($0.typeName)"
        }
        print("\(indent)init(\(initArgs.joined(separator: ", "))) {")
        data.initializer.creations.forEach {
            print("\(indent)\(indent)\($0)")
        }
        print()
        data.initializer.propertyInjections.forEach {
            print("\(indent)\(indent)\($0)")
        }
        print()
        data.initializer.storedProperties.forEach {
            print("\(indent)\(indent)\($0)")
        }
        print("\(indent)}")
        print("}")
        
        print()
        print("extension \(data.name) {")
        data.getters.forEach {
            print()
            print("\(indent)var \($0.name): \($0.typeName) {")
            $0.body.forEach {
                print("\(indent)\(indent)\($0)")
            }
            print("\(indent)}")
        }
        print("}")
    }
}
