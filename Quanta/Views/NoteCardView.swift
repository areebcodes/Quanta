import SwiftUI

struct NoteCardView: View {
    @ObservedObject var note: Note
    var accentColor: Color?

    private var formattedDate: String {
        guard let date = note.updatedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var subjectName: String? {
        note.subject?.name
    }

    private var subjectColorValue: Color {
        accentColor ?? QuantaTheme.color(for: note.subject?.colorName ?? "blue")
    }

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            thumbnailView
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: QuantaTheme.smallRadius, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title ?? "Untitled")
                    .font(QuantaTheme.headline)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    if note.pdfData != nil {
                        Label("PDF", systemImage: "doc.richtext.fill")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.gradient, in: Capsule())
                    }

                    if let name = subjectName {
                        Text(name)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(subjectColorValue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(subjectColorValue.opacity(0.12), in: Capsule())
                    }

                    Spacer()

                    Text(formattedDate)
                        .font(QuantaTheme.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: QuantaTheme.smallRadius, style: .continuous)
                .fill(Color(.systemGray6))

            if let data = note.thumbnailData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if note.pdfData != nil {
                Image(systemName: "doc.richtext.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "pencil.tip")
                    .font(.title3)
                    .foregroundStyle(.quaternary)
            }
        }
    }
}
