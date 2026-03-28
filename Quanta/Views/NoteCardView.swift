import SwiftUI

struct NoteCardView: View {
    @ObservedObject var note: Note

    private var formattedDate: String {
        guard let date = note.updatedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailArea
            infoArea
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var thumbnailArea: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray6))

            if let data = note.thumbnailData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if note.pdfData != nil {
                VStack(spacing: 8) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 36))
                    Text("PDF")
                        .font(.caption.bold())
                }
                .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 36))
                    Text("Drawing")
                        .font(.caption.bold())
                }
                .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipped()
    }

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title ?? "Untitled")
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
    }
}
