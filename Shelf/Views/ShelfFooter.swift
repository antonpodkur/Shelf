import SwiftUI

struct ShelfFooter: View {
    let itemCount: Int
    let totalSize: String
    let onExportFolder: () -> Void
    let onExportZip: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(itemCount) \(itemCount == 1 ? "item" : "items") \u{2022} \(totalSize)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Export Folder") { onExportFolder() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Button("Export Zip") { onExportZip() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            Button("Clear") { onClear() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
