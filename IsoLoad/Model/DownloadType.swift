//
//  DownloadType.swift
//  IsoLoad
//
//  Created by Nindi Gill on 13/6/2022.
//  Modified by Stanley Lollia - Added ISO support
//

enum DownloadType: String, CaseIterable, Identifiable {
    case firmware = "Firmware"
    case installer = "Installer"
    case iso = "ISO"

    var id: String {
        rawValue
    }

    var description: String {
        rawValue
    }
}
