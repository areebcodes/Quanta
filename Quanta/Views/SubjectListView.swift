import SwiftUI
import CoreData

struct SubjectListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subject.sortOrder, ascending: true)],
        animation: .spring(response: 0.35)
    )
    private var subjects: FetchedResults<Subject>

    @Binding var selection: SidebarItem?

    @State private var showingNewSubject = false
    @State private var editingSubject: Subject?

    // Count all notes for "All Notes" row
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    )
    private var allNotes: FetchedResults<Note>

    var body: some View {
        List(selection: $selection) {
            // MARK: All Notes
            Section {
                Label {
                    HStack {
                        Text("All Notes")
                            .font(QuantaTheme.headline)
                        Spacer()
                        Text("\(allNotes.count)")
                            .font(QuantaTheme.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } icon: {
                    Image(systemName: "tray.full.fill")
                        .foregroundStyle(.primary)
                        .font(.title3)
                }
                .tag(SidebarItem.allNotes)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }

            // MARK: Subjects
            Section {
                ForEach(subjects, id: \.objectID) { subject in
                    SubjectRow(subject: subject)
                        .tag(SidebarItem.subject(subject.objectID))
                        .contextMenu {
                            Button {
                                editingSubject = subject
                            } label: {
                                Label("Edit Subject", systemImage: "pencil")
                            }
                            Divider()
                            Button(role: .destructive) {
                                deleteSubject(subject)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onMove(perform: moveSubjects)
            } header: {
                Text("Subjects")
                    .font(QuantaTheme.captionBold)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Quanta")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewSubject = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingNewSubject) {
            SubjectEditorSheet(subject: nil)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingSubject) { subject in
            SubjectEditorSheet(subject: subject)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            if selection == nil {
                selection = .allNotes
            }
        }
    }

    private func deleteSubject(_ subject: Subject) {
        withAnimation {
            // Unlink notes from subject before deleting
            if let notes = subject.notes as? Set<Note> {
                for note in notes {
                    note.subject = nil
                }
            }
            viewContext.delete(subject)
            try? viewContext.save()
            if case .subject(let id) = selection, id == subject.objectID {
                selection = .allNotes
            }
        }
    }

    private func moveSubjects(from source: IndexSet, to destination: Int) {
        var ordered = Array(subjects)
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, subject) in ordered.enumerated() {
            subject.sortOrder = Int16(index)
        }
        try? viewContext.save()
    }
}

// MARK: - Subject Row

struct SubjectRow: View {
    @ObservedObject var subject: Subject

    private var noteCount: Int {
        (subject.notes as? Set<Note>)?.count ?? 0
    }

    var body: some View {
        Label {
            HStack {
                Text(subject.name ?? "Subject")
                    .font(QuantaTheme.headline)
                    .lineLimit(1)
                Spacer()
                Text("\(noteCount)")
                    .font(QuantaTheme.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } icon: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(QuantaTheme.color(for: subject.colorName ?? "blue").gradient)
                    .frame(width: 32, height: 32)
                Text(subject.emoji ?? "📓")
                    .font(.system(size: 16))
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
                Section {
                    // Preview
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
