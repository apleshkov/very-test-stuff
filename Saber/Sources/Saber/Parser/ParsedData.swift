//
//  ParsedData.swift
//  Saber
//
//  Created by andrey.pleshkov on 29/05/2018.
//

import Foundation

struct ParsedData {

    private var types: [String : ParsedType] = [:]

    init() {
    }

    func register(_ type: ParsedType) {}

    func register(_ ext: ParsedExtension) {}
}
