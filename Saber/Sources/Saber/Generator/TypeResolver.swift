//
//  TypeResolver.swift
//  Saber
//
//  Created by andrey.pleshkov on 30/05/2018.
//

import Foundation

indirect enum TypeResolver<T> {
    case explicit(T)
    case provided(TypeUsage, by: TypeProvider)
    case bound(TypeUsage, to: T)
    case derived(from: T, typeResolver: TypeResolver)
    case external(from: T, kind: ContainerExternal.Kind)
}
