import SwiftUI
import CoreData

// MARK: - Sidebar

struct SidebarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedSubject: Subject?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subject.sortOrder, ascending: true)]
    ) private var subjects: FetchedResults<Subject>

    @State private var showNewSubject = false
    @State private var editingSubject: Subject?
    @State private var showEditSheet = false
    @State private var shimmerPhase: CGFloat = -0.3

    var body: some View {
        ZStack {
            QuantaTheme.sidebarBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Wordmark with gold shimmer
                Text("Quanta")
                    .font(QuantaTheme.wordmark)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [QuantaTheme.gold, QuantaTheme.goldLight, QuantaTheme.gold],
                            startPoint: UnitPoint(x: shimmerPhase, y: 0.5),
                            endPoint: UnitPoint(x: shimmerPhase + 0.6, y: 0.5)
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            shimmerPhase = 1.3
                        }
                    }

                // All Notes
                Button {
                    selectedSubject = nil
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "note.text")
                            .font(.system(size: 15, weight: .medium))
                        Text("All Notes")
                            .font(QuantaTheme.headline)
                        Spacer()
                    }
                    .foregroundStyle(selectedSubject == nil ? QuantaTheme.gold : .white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        selectedSubject == nil ? QuantaTheme.goldDim : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.plain)

                // Subjects header
                HStack {
                    Text("SUBJECTS")
                        .font(QuantaTheme.captionBold)
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Button { showNewSubject = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)

                // Subject list
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(subjects, id: \.objectID) { subject in
                            subjectRow(subject)
                        }
                    }
                }

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNewSubject) {
            SubjectEditorSheet(subject: nil)
        }
        .sheet(isPresented: $showEditSheet) {
            if let editingSubject {
                SubjectEditorSheet(subject: editingSubject)
            }
        }
    }

    private func subjectRow(_ subject: Subject) -> some View {
        Button {
            selectedSubject = subject
        } label: {
            HStack(spacing: 10) {
                Text(subject.emoji ?? "📓")
                    .font(.system(size: 18))
                Text(subject.name ?? "")
                    .font(QuantaTheme.body)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text("\(subject.notes?.count ?? 0)")
                    .font(QuantaTheme.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                selectedSubject?.objectID == subject.objectID
                    ? QuantaTheme.color(for: subject.colorName ?? "blue").opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editingSubject = subject
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                if selectedSubject?.objectID == subject.objectID {
                    selectedSubject = nil
                }
                viewContext.delete(subject)
                try? viewContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

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
