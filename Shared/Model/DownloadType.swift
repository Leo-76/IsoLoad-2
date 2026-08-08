//
//  DownloadType.swift
//  IsoLoad
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
