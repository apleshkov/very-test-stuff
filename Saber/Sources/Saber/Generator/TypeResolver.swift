//
//  TypeResolver.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

indirect enum TypeResolver {
    case explicit(Type)
    case provided(Type, by: TypeProvider)
    case bound(Type, to: Type)
    case derived(from: Type, typeResolver: TypeResolver)
    case external(from: Type, kind: ContainerExternal.Kind)
}
