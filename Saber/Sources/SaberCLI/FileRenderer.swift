//
//  FileRenderer.swift
//  SaberCLI
//
//  Created by andrey.pleshkov on 03/07/2018.
//

import Foundation
import Basic

class FileRenderer {


}

public static func render(containers: [Container], to pathString: String, config: SaberConfiguration) throws {
    let path = AbsolutePath(pathString)
    let dataFactory = ContainerDataFactory()
    try containers.forEach {
        let data = dataFactory.make(from: $0)
        let renderer = Renderer(data: data, config: config.indent)
        let generated = renderer.render()
        //let containerPath = path.
    }
}
