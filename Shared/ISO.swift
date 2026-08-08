//
//  ISO.swift
//  IsoLoad
//
//  Created by Stanley Lollia
//

import Foundation

struct ISO: Identifiable, Codable, Hashable {
    let name: String
    let version: String
    let date: String
    let size: String
    let url: String
    let icon: String

    var id: String { "\(name)-\(version)" }
}

struct ISOCatalog: Codable {
    let isos: [ISO]
}
