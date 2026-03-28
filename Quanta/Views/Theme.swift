import SwiftUI

// MARK: - Design System

enum QuantaTheme {
    // MARK: Typography
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title2, design: .rounded, weight: .bold)
    static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .rounded)
    static let subheadline = Font.system(.subheadline, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
    static let captionBold = Font.system(.caption2, design: .rounded, weight: .bold)

    // MARK: Radius
    static let cornerRadius: CGFloat = 16
    static let smallRadius: CGFloat = 10
    static let pillRadius: CGFloat = 24

    // MARK: Spacing
    static let padding: CGFloat = 20
    static let smallPadding: CGFloat = 12
    static let tinyPadding: CGFloat = 6

    // MARK: Subject Colors
    static let subjectColors: [(name: String, color: Color, darkColor: Color)] = [
        ("red", .red, Color(red: 1.0, green: 0.35, blue: 0.35)),
        ("orange", .orange, Color(red: 1.0, green: 0.6, blue: 0.25)),
        ("yellow", Color(red: 0.85, green: 0.75, blue: 0.0), Color(red: 1.0, green: 0.85, blue: 0.2)),
        ("green", Color(red: 0.2, green: 0.75, blue: 0.4), Color(red: 0.35, green: 0.85, blue: 0.5)),
        ("mint", .mint, .mint),
        ("teal", .teal, .teal),
        ("blue", .blue, Color(red: 0.35, green: 0.55, blue: 1.0)),
        ("indigo", .indigo, Color(red: 0.5, green: 0.45, blue: 1.0)),
        ("purple", .purple, Color(red: 0.7, green: 0.4, blue: 1.0)),
        ("pink", .pink, Color(red: 1.0, green: 0.4, blue: 0.6)),
    ]

    static func color(for name: String) -> Color {
        subjectColors.first { $0.name == name }?.color ?? .blue
    }

    // MARK: Emoji Presets
    static let emojiPresets = [
        "📓", "📕", "📗", "📘", "📙", "📒",
        "🔬", "🧮", "🎨", "🎵", "📐", "🌍",
        "💻", "📊", "✏️", "🧪", "📖", "🏛️",
        "⚡", "🎯", "🧠", "💡", "🔧", "🚀",
    ]
}

// MARK: - Canvas Style

enum CanvasStyle: Int16, CaseIterable, Identifiable {
    case blank = 0
    case ruled = 1
    case grid = 2
    case dotted = 3

    var id: Int16 { rawValue }

    var icon: String {
        switch self {
        case .blank: "doc"
        case .ruled: "line.3.horizontal"
        case .grid: "squareshape.split.3x3"
        case .dotted: "circle.grid.3x3"
        }
    }

    var label: String {
        switch self {
        case .blank: "Blank"
        case .ruled: "Ruled"
        case .grid: "Grid"
        case .dotted: "Dotted"
        }
    }
}

// MARK: - Sidebar Selection

enum SidebarItem: Hashable {
    case allNotes
    case subject(NSManagedObjectID)
}

// MARK: - View Modifiers

struct PremiumCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: QuantaTheme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.03), radius: 2, x: 0, y: 1)
    }
}

struct FloatingPillStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func premiumCard() -> some View {
        modifier(PremiumCardStyle())
    }

    func floatingPill() -> some View {
        modifier(FloatingPillStyle())
    }
}

// MARK: - Core Data Helpers

import CoreData

extension NSManagedObjectID: @retroactive Identifiable {
    public var id: NSManagedObjectID { self }
}
