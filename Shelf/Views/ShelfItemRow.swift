import SwiftUI

struct ShelfItemRow: View {
    let item: ShelfItem
    let onRemove: () -> Void
    var onHoverChange: ((Bool) -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(item.formattedSize) \u{2022} \(item.dateAdded, format: .relative(presentation: .named))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            onHoverChange?(hovering)
        }
        .contextMenu {
            Button("Open") {
                NSWorkspace.shared.open(item.vaultURL)
            }
            Button("Reveal in Finder") {
                NSWorkspace.shared.selectFile(item.vaultURL.path, inFileViewerRootedAtPath: item.vaultURL.deletingLastPathComponent().path)
            }
            Button("Copy to Clipboard") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([item.vaultURL as NSURL])
            }
            Divider()
            Button("Remove from Shelf", role: .destructive) {
                onRemove()
            }
        }
    }

    private var thumbnail: some View {
        Group {
            if let nsImage = NSWorkspace.shared.icon(forFile: item.vaultURL.path) as NSImage? {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "doc")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
