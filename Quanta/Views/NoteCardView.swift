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
            // Thumbnail
            ZStack {
                Color(white: 0.15)

                if let data = note.thumbnailData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else if note.pdfData != nil {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.2))
                } else {
                    Image(systemName: "pencil.tip")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.15))
                }
            }
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(note.title ?? "Untitled")
                    .font(QuantaTheme.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let subject = note.subject {
                        SubjectPill(subject: subject)
                    }

                    if note.pdfData != nil {
                        Text("PDF")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.blue.gradient, in: Capsule())
                    }

                    Spacer()

                    Text(formattedDate)
                        .font(QuantaTheme.caption)
                        .foregroundStyle(.white.opacity(0.35))
                        .monospacedDigit()
                }
            }
            .padding(12)
            .background(QuantaTheme.cardBg)
        }
        .clipShape(RoundedRectangle(cornerRadius: QuantaTheme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: QuantaTheme.cornerRadius, style: .continuous)
                .stroke(QuantaTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Subject Pill

struct SubjectPill: View {
    @ObservedObject var subject: Subject

    var body: some View {
        HStack(spacing: 3) {
            Text(subject.emoji ?? "📓")
                .font(.system(size: 9))
            Text(subject.name ?? "")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            QuantaTheme.color(for: subject.colorName ?? "blue").opacity(0.5),
            in: Capsule()
        )
    }
}
