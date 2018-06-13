//
//  MethodAnnotation.swift
//  Saber
//
//  Created by andrey.pleshkov on 29/05/2018.
//

import Foundation

enum MethodAnnotation: Equatable {
    case inject
    case provider
    case cached // only for providers
    case didInject
}
