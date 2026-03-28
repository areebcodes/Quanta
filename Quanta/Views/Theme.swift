import SwiftUI
import CoreData

// MARK: - Design System

enum QuantaTheme {
    // Brand
    static let gold = Color(red: 0.961, green: 0.773, blue: 0.259)
    static let goldLight = Color(red: 0.98, green: 0.87, blue: 0.45)
    static let goldDim = gold.opacity(0.25)

    // Chrome
    static let darkBg = Color(red: 0.05, green: 0.05, blue: 0.05)         // #0D0D0D
    static let sidebarBg = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let cardBg = Color(white: 0.10)
    static let cardBorder = gold.opacity(0.2)
    static let searchBg = Color(white: 0.13)
    static let toolbarBg = Color(white: 0.04)
    static let topBarBg = Color.black.opacity(0.88)
    static let pageBg = Color(white: 0.05)

    // Typography
    static let wordmark = Font.system(size: 28, weight: .heavy, design: .rounded)
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
    static let pageGap: CGFloat = 24
    static let pageRatio: CGFloat = 11.0 / 8.5

    // Subject colors
    static let subjectColors: [(name: String, color: Color)] = [
        ("red", .red), ("orange", .orange),
        ("yellow", Color(red: 0.9, green: 0.8, blue: 0.0)),
        ("green", Color(red: 0.2, green: 0.78, blue: 0.4)),
        ("mint", .mint), ("teal", .teal), ("blue", .blue),
        ("indigo", .indigo), ("purple", .purple), ("pink", .pink),
    ]

    static func color(for name: String) -> Color {
        subjectColors.first { $0.name == name }?.color ?? .blue
    }

    // Canvas style (for background view compatibility)
    enum CanvasStyle: Int16, CaseIterable {
        case blank = 0, ruled, grid, dotted
    }

    static let emojiPresets = [
        "📓", "📕", "📗", "📘", "📙", "📒",
        "🔬", "🧮", "🎨", "🎵", "📐", "🌍",
        "💻", "📊", "✏️", "🧪", "📖", "🏛️",
    ]
}

// MARK: - Canvas Tool

enum CanvasTool: String {
    case pen, highlighter, eraser, lasso

    var icon: String {
        switch self {
        case .pen: "pencil.tip"
        case .highlighter: "highlighter"
        case .eraser: "eraser"
        case .lasso: "lasso"
        }
    }
}

// MARK: - Tool Size

enum ToolSize: String, CaseIterable {
    case thin, medium, thick

    var label: String { rawValue.capitalized }

    func width(for tool: CanvasTool) -> CGFloat {
        switch (tool, self) {
        case (.pen, .thin): 1.5
        case (.pen, .medium): 3.0
        case (.pen, .thick): 6.0
        case (.highlighter, .thin): 10
        case (.highlighter, .medium): 18
        case (.highlighter, .thick): 28
        case (.eraser, .thin): 12
        case (.eraser, .medium): 24
        case (.eraser, .thick): 44
        case (.lasso, _): 0
        }
    }

    var dotSize: CGFloat {
        switch self {
        case .thin: 6
        case .medium: 12
        case .thick: 20
        }
    }
}

// MARK: - Toolbar Color Swatches

enum ToolbarSwatch: CaseIterable {
    case black, gold, blue, green, red, custom

    var color: Color {
        switch self {
        case .black: .black
        case .gold: QuantaTheme.gold
        case .blue: Color(red: 0.2, green: 0.4, blue: 1.0)
        case .green: Color(red: 0.15, green: 0.75, blue: 0.35)
        case .red: Color(red: 0.95, green: 0.2, blue: 0.25)
        case .custom: .clear
        }
    }
}
