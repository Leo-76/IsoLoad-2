//
//  ISO.swift
//  IsoLoad
//

import Foundation

struct ISO: Identifiable, Codable {
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
