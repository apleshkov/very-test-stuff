//
//  foo.swift
//  Parser
//
//  Created by andrey.pleshkov on 08/05/2018.
//

import Foundation

public func foo() -> Bool { return true }



protocol Scope {}

protocol Singleton: Scope {}

protocol Containing {}


class XXX: Containing {}


protocol ContainerConfiguration {

    static var name: String { get }

    static var scope: Any.Type { get }

    static var dependencies: [Containing.Type] { get }

    static var externals: [Any.Type] { get }
}

// @saber.name(AppContainer)
// @saber.scope(Singleton)
// @saber.dependsOn(XXX)
// @saber.externals(XXX, Env)
private struct AppContainerConfiguration: ContainerConfiguration {

    static let name: String = "AppContainer"

    static var scope: Any.Type = Singleton.self

    static var dependencies: [Containing.Type] = [XXX.self]

    static var externals: [Any.Type] = [XXX.self]
}
