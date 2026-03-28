import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Quanta")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        seedDefaultSubjects(context: container.viewContext)
    }

    private func seedDefaultSubjects(context: NSManagedObjectContext) {
        let request = Subject.fetchRequest()
        let count = (try? context.count(for: request)) ?? 0
        guard count == 0 else { return }

        let defaults: [(String, String, String, Int16)] = [
            ("Math", "🧮", "blue", 0),
            ("Science", "🔬", "green", 1),
            ("English", "📖", "red", 2),
            ("History", "🏛️", "orange", 3),
            ("Art", "🎨", "purple", 4),
        ]

        for (name, emoji, color, order) in defaults {
            let subject = Subject(context: context)
            subject.id = UUID()
            subject.name = name
            subject.emoji = emoji
            subject.colorName = color
            subject.sortOrder = order
            subject.createdAt = Date()
        }

        try? context.save()
    }
}
