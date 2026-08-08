//
//  ContentView.swift
//  IsoLoad
//
//  Created by Nindi Gill on 13/6/2022.
//  Modified by Stanley Lollia - Added ISO support
//

import SwiftUI

struct ContentView: View {
    @Environment(\.openURL)
    var openURL: OpenURLAction
    @AppStorage("downloadType")
    private var downloadType: DownloadType = .firmware
    @AppStorage("includeBetas")
    private var includeBetas: Bool = false
    @AppStorage("showCompatible")
    private var showCompatible: Bool = false
    @Binding var refreshing: Bool
    @Binding var tasksInProgress: Bool
    @State private var firmwares: [Firmware] = []
    @State private var installers: [Installer] = []
    @State private var isos: [ISO] = []
    @State private var searchString: String = ""
    @State private var openPanel: NSOpenPanel = NSOpenPanel()
    @State private var savePanel: NSSavePanel = NSSavePanel()
    @State private var copiedToClipboard: Bool = false
    @StateObject private var taskManager: TaskManager = .shared

    private var filteredFirmwares: [Firmware] {
        var filteredFirmwares: [Firmware] = firmwares

        if !searchString.isEmpty {
            let string: String = searchString.lowercased()
            filteredFirmwares = filteredFirmwares.filter {
                $0.name.lowercased().contains(string) ||
                    $0.version.lowercased().contains(string) ||
                    $0.build.lowercased().contains(string) ||
                    $0.formattedDate.lowercased().contains(string)
            }
        }

        if !includeBetas {
            filteredFirmwares = filteredFirmwares.filter { !$0.beta }
        }

        if showCompatible {
            filteredFirmwares = filteredFirmwares.filter(\.compatible)
        }

        return filteredFirmwares
    }

    private var filteredInstallers: [Installer] {
        var filteredInstallers: [Installer] = installers

        if !searchString.isEmpty {
            let string: String = searchString.lowercased()
            filteredInstallers = filteredInstallers.filter {
                $0.name.lowercased().contains(string) ||
                    $0.version.lowercased().contains(string) ||
                    $0.build.lowercased().contains(string) ||
                    $0.date.lowercased().contains(string)
            }
        }

        if !includeBetas {
            filteredInstallers = filteredInstallers.filter { !$0.beta }
        }

        if showCompatible {
            filteredInstallers = filteredInstallers.filter(\.compatible)
        }

        return filteredInstallers
    }

    private var filteredISOs: [ISO] {
        guard !searchString.isEmpty else { return isos }
        let string: String = searchString.lowercased()
        return isos.filter {
            $0.name.lowercased().contains(string) ||
                $0.version.lowercased().contains(string)
        }
    }

    private var isEmpty: Bool {
        switch downloadType {
        case .firmware: return filteredFirmwares.isEmpty
        case .installer: return filteredInstallers.isEmpty
        case .iso: return filteredISOs.isEmpty
        }
    }

    private let width: CGFloat = 480
    private let height: CGFloat = 720

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(downloadType: $downloadType)
            Divider()
            if isEmpty {
                EmptyCollectionView("No \(downloadType.description)s found!\n\nಥ_ಥ")
            } else {
                ZStack {
                    List {
                        switch downloadType {
                        case .firmware:
                            ForEach(releaseNames(for: downloadType), id: \.self) { releaseName in
                                Section(header: Text(releaseName)) {
                                    ForEach(filteredFirmwares(for: releaseName)) { firmware in
                                        ListRowFirmware(firmware: firmware, savePanel: $savePanel, copiedToClipboard: $copiedToClipboard, tasksInProgress: $tasksInProgress, taskManager: taskManager)
                                            .tag(firmware)
                                    }
                                }
                            }
                        case .installer:
                            ForEach(releaseNames(for: downloadType), id: \.self) { releaseName in
                                Section(header: Text(releaseName)) {
                                    ForEach(filteredInstallers(for: releaseName)) { installer in
                                        ListRowInstaller(installer: installer, openPanel: $openPanel, tasksInProgress: $tasksInProgress, taskManager: taskManager)
                                            .tag(installer)
                                    }
                                }
                            }
                        case .iso:
                            ForEach(isoReleaseNames(), id: \.self) { releaseName in
                                Section(header: Text(releaseName)) {
                                    ForEach(filteredISOs.filter { $0.name == releaseName }) { iso in
                                        ListRowISO(iso: iso)
                                            .tag(iso)
                                    }
                                }
                            }
                        }
                    }
                    if copiedToClipboard {
                        FloatingAlert(image: "list.bullet.clipboard.fill", message: "Copied to Clipboard")
                    }
                }
            }
            Divider()
            FooterView(
                includeBetas: $includeBetas,
                showCompatible: $showCompatible,
                downloadType: downloadType,
                firmwares: $firmwares,
                installers: $installers,
                isos: $isos
            )
        }
        .frame(width: width, height: height)
        .toolbar {
            Button {
                refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .foregroundColor(.accentColor)
            }
            .help("Refresh")
            Button {
                showLog()
            } label: {
                Label("Show Log", systemImage: "text.and.command.macwindow")
                    .foregroundColor(.accentColor)
            }
            .help("Show IsoLoad Log")
        }
        .searchable(text: $searchString)
        .sheet(isPresented: $refreshing) {
            RefreshView(firmwares: $firmwares, installers: $installers)
        }
        .onAppear {
            refresh()
            loadISOs()
        }
        .onChange(of: copiedToClipboard) { copied in
            guard copied else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    copiedToClipboard = false
                }
            }
        }
    }

    private func refresh() {
        refreshing = true
    }

  
    private func loadISOs() {
        Task {
            do {
                let fetched = try await ISOService.fetchISOs()
                print("ISOs chargées: \(fetched.count)")
                await MainActor.run {
                    isos = fetched
                }
            } catch {
                print("Erreur chargement ISOs: \(error)")
            }
        }
    }

    private func showLog() {
        guard let url = URL(string: .logURL) else { return }
        openURL(url)
    }

    private func releaseNames(for type: DownloadType) -> [String] {
        var releaseNames: [String] = []

        switch type {
        case .firmware:
            for firmware in filteredFirmwares {
                let releaseName: String = firmware.name.replacingOccurrences(of: " beta", with: "")
                if !releaseNames.contains(releaseName) {
                    releaseNames.append(releaseName)
                }
            }
        case .installer:
            for installer in filteredInstallers {
                let releaseName: String = installer.name.replacingOccurrences(of: " beta", with: "")
                if !releaseNames.contains(releaseName) {
                    releaseNames.append(releaseName)
                }
            }
        case .iso:
            break
        }

        return releaseNames
    }

    private func isoReleaseNames() -> [String] {
        var names: [String] = []
        for iso in filteredISOs {
            if !names.contains(iso.name) {
                names.append(iso.name)
            }
        }
        return names
    }

    private func filteredFirmwares(for releaseName: String) -> [Firmware] {
        filteredFirmwares.filter { $0.name.replacingOccurrences(of: " beta", with: "") == releaseName }
    }

    private func filteredInstallers(for releaseName: String) -> [Installer] {
        filteredInstallers.filter { $0.name.replacingOccurrences(of: " beta", with: "") == releaseName }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(refreshing: .constant(false), tasksInProgress: .constant(false))
    }
}
