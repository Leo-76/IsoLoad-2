//
//  ISOService.swift
//  IsoLoad
//

import Foundation

struct ISOService {
    static let catalogURL = "https://raw.githubusercontent.com/Leo-76/IsoLoad-2/main/isos.json"
    
    static func fetchISOs() async throws -> [ISO] {
        guard let url = URL(string: catalogURL) else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let catalog = try JSONDecoder().decode(ISOCatalog.self, from: data)
        return catalog.isos
    }
}
