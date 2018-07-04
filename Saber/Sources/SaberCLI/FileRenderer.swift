//
//  FileRenderer.swift
//  SaberCLI
//
//  Created by andrey.pleshkov on 03/07/2018.
//

import Foundation
import Basic
import Saber

class FileRenderer {

    let dirURL: URL

    let config: SaberConfiguration

    init(pathString: String, config: SaberConfiguration) {
        self.dirURL = URL(fileURLWithPath: pathString)
        self.config = config
    }

    func render(containers: [Container]) throws {
        let dataFactory = ContainerDataFactory(config: config)
        try containers.forEach {
            let data = dataFactory.make(from: $0)
            let renderer = Renderer(data: data, config: config)
            let generated = renderer.render()
            let containerURL = dirURL.appendingPathComponent("\($0.name).swift")
            try generated.write(to: containerURL, atomically: false, encoding: .utf8)
        }
    }
}
