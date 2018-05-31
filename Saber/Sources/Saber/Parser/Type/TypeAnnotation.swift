//
//  TypeAnnotation.swift
//  Saber
//
//  Created by andrey.pleshkov on 29/05/2018.
//

import Foundation

enum TypeAnnotation: Equatable {
    case bound(to: ParsedTypeUsage)
    case cached
    case injectOnly    
}
