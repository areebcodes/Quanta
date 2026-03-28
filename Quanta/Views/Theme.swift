import SwiftUI
import CoreData

// MARK: - Design System

enum QuantaTheme {
    // Brand colors
    static let gold = Color(red: 0.961, green: 0.773, blue: 0.259)         // #F5C542
    static let goldLight = Color(red: 0.98, green: 0.87, blue: 0.45)
    static let goldDim = Color(red: 0.961, green: 0.773, blue: 0.259).opacity(0.25)

    // Chrome
    static let darkBg = Color.black
    static let cardBg = Color(white: 0.10)
    static let cardBorder = gold.opacity(0.2)
    static let searchBg = Color(white: 0.13)
    static let toolbarBg = Color(white: 0.06)
    static let topBarBg = Color.black.opacity(0.88)

    // Typography
    static let wordmark = Font.system(size: 34, weight: .heavy, design: .rounded)
    static let title = Font.system(.title2, design: .rounded, weight: .bold)
    static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .rounded)
    static let subheadline = Font.system(.subheadline, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
    static let captionBold = Font.system(.caption2, design: .rounded, weight: .bold)

    // Layout
    static let cornerRadius: CGFloat = 16
    static let smallRadius: CGFloat = 10

    // Subject colors
    static let subjectColors: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", Color(red: 0.9, green: 0.8, blue: 0.0)),
        ("green", Color(red: 0.2, green: 0.78, blue: 0.4)),
        ("mint", .mint),
        ("teal", .teal),
        ("blue", .blue),
        ("indigo", .indigo),
        ("purple", .purple),
        ("pink", .pink),
    ]

    static func color(for name: String) -> Color {
        subjectColors.first { $0.name == name }?.color ?? .blue
    }

    static let emojiPresets = [
        "📓", "📕", "📗", "📘", "📙", "📒",
        "🔬", "🧮", "🎨", "🎵", "📐", "🌍",
        "💻", "📊", "✏️", "🧪", "📖", "🏛️",
        "⚡", "🎯", "🧠", "💡", "🔧", "🚀",
    ]
}

// MARK: - Canvas Tool

enum CanvasTool: String {
    case pen
    case highlighter
    case eraser
    case lasso

    var icon: String {
        switch self {
        case .pen: "pencil.tip"
        case .highlighter: "highlighter"
        case .eraser: "eraser"
        case .lasso: "lasso"
        }
    }

    var label: String {
        switch self {
        case .pen: "Pen"
        case .highlighter: "Highlighter"
        case .eraser: "Eraser"
        case .lasso: "Lasso"
        }
    }
}

// MARK: - Canvas Style

enum CanvasStyle: Int16 {
    case blank = 0
    case ruled = 1
    case grid = 2
    case dotted = 3

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
