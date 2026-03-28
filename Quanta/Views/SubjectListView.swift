import SwiftUI
import CoreData

// MARK: - Subject Editor Sheet

struct SubjectEditorSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let subject: Subject?

    @State private var name = ""
    @State private var emoji = "📓"
    @State private var selectedColor = "blue"

    private var isEditing: Bool { subject != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Preview
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(QuantaTheme.color(for: selectedColor).gradient)
                                .frame(width: 72, height: 72)
                            Text(emoji)
                                .font(.system(size: 36))
                        }
                        .shadow(color: QuantaTheme.color(for: selectedColor).opacity(0.4), radius: 12, y: 6)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                }

                Section("Name") {
                    TextField("Subject name", text: $name)
                        .font(QuantaTheme.body)
                }

                Section("Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(QuantaTheme.emojiPresets, id: \.self) { e in
                            Button {
                                emoji = e
                            } label: {
                                Text(e)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        emoji == e
                                            ? Color.accentColor.opacity(0.15)
                                            : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(QuantaTheme.subjectColors, id: \.name) { item in
                            Button {
                                selectedColor = item.name
                            } label: {
                                Circle()
                                    .fill(item.color.gradient)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if selectedColor == item.name {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Subject" : "New Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let subject {
                    name = subject.name ?? ""
                    emoji = subject.emoji ?? "📓"
                    selectedColor = subject.colorName ?? "blue"
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let target = subject ?? Subject(context: viewContext)
        if subject == nil {
            target.id = UUID()
            target.createdAt = Date()
            target.sortOrder = Int16(999)
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.emoji = emoji
        target.colorName = selectedColor
        try? viewContext.save()
    }
}
