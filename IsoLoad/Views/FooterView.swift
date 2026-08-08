//
//  FooterView.swift
//  IsoLoad
//
//  Created by Nindi Gill on 28/6/2022.
//  Modified by Stanley Lollia - Added ISO support
//

import SwiftUI

struct FooterView: View {
    @Binding var includeBetas: Bool
    @Binding var showCompatible: Bool
    var downloadType: DownloadType
    @Binding var firmwares: [Firmware]
    @Binding var installers: [Installer]
    @Binding var isos: [ISO]
    @State private var savePanel: NSSavePanel = .init()
    @State private var exportListType: ExportListType = .json
    private let dateFormatter: DateFormatter = .init()

    var body: some View {
        HStack {
            if downloadType != .iso {
                Toggle("Include Betas", isOn: $includeBetas)
                Toggle("Only show compatible versions", isOn: $showCompatible)
            }
            Spacer()
            Button("Export List...") {
                export()
            }
        }
        .padding()
        .onChange(of: exportListType) { _ in
            updateSavePanel()
        }
    }

    private func export() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date: String = dateFormatter.string(from: Date())
        savePanel.title = "Export \(downloadType.description) List"
        savePanel.prompt = "Export"
        savePanel.nameFieldStringValue = "IsoLoad \(downloadType.description) \(date)"
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = false
        savePanel.allowedContentTypes = [exportListType.contentType]
        savePanel.accessoryView = NSHostingView(rootView: ExportListView(exportListType: $exportListType))

        let response: NSApplication.ModalResponse = savePanel.runModal()

        guard
            response == .OK,
            let url: URL = savePanel.url else {
            return
        }

        let dictionaries: [[String: Any]] = switch downloadType {
        case .firmware:
            firmwares.map(\.dictionary)
        case .installer:
            installers.map(\.dictionary)
        case .iso:
            isos.map { ["name": $0.name, "version": $0.version, "date": $0.date, "size": $0.size, "url": $0.url] }
        }

        do {
            switch exportListType {
            case .csv:
                switch downloadType {
                case .firmware:
                    try dictionaries.firmwaresCSVString().write(to: url, atomically: true, encoding: .utf8)
                case .installer:
                    try dictionaries.installersCSVString().write(to: url, atomically: true, encoding: .utf8)
                case .iso:
                    try dictionaries.jsonString().write(to: url, atomically: true, encoding: .utf8)
                }
            case .json:
                try dictionaries.jsonString().write(to: url, atomically: true, encoding: .utf8)
            case .plist:
                try dictionaries.propertyListString().write(to: url, atomically: true, encoding: .utf8)
            case .yaml:
                try dictionaries.yamlString().write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    private func updateSavePanel() {
        savePanel.allowedContentTypes = [exportListType.contentType]
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView(includeBetas: .constant(true), showCompatible: .constant(false), downloadType: .firmware, firmwares: .constant([.example]), installers: .constant([]), isos: .constant([]))
        FooterView(includeBetas: .constant(true), showCompatible: .constant(false), downloadType: .installer, firmwares: .constant([]), installers: .constant([.example]), isos: .constant([]))
        FooterView(includeBetas: .constant(true), showCompatible: .constant(false), downloadType: .iso, firmwares: .constant([]), installers: .constant([]), isos: .constant([]))
    }
}
