//
//  ListRowISO.swift
//  IsoLoad
//
//  Created by Stanley Lollia
//

import SwiftUI

struct ListRowISO: View {
    var iso: ISO

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(iso.name) \(iso.version)")
                    .font(.headline)
                HStack {
                    Text(iso.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(iso.size)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                download()
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Download \(iso.name) \(iso.version) ISO")
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch iso.icon.lowercased() {
        case "windows": return "desktopcomputer"
        case "ubuntu", "debian", "fedora": return "terminal"
        default: return "opticaldisc"
        }
    }

    private var iconColor: Color {
        switch iso.icon.lowercased() {
        case "windows": return .blue
        case "ubuntu": return .orange
        case "debian": return .red
        case "fedora": return .indigo
        default: return .gray
        }
    }

    private func download() {
        guard let url = URL(string: iso.url) else { return }
        NSWorkspace.shared.open(url)
    }
}
