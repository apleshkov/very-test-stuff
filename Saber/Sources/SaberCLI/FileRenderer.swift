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

    let path: AbsolutePath

    let config: SaberConfiguration

    init(pathString: String, config: SaberConfiguration) {
        self.path = AbsolutePath(pathString)
        self.config = config
    }

    func render(containers: [Container]) throws {
        let dataFactory = ContainerDataFactory()
        try containers.forEach {
            let data = dataFactory.make(from: $0)
            let renderer = Renderer(data: data, config: config)
            let generated = renderer.render()
            let containerPath = path.appending(component: "\($0.name).swift")
            let byteString = ByteString(encodingAsUTF8: generated)
            try localFileSystem.writeFileContents(containerPath, bytes: byteString)
        }
    }
}
