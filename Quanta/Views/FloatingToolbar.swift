import SwiftUI

struct FloatingToolbar: View {
    @Binding var canvasStyle: CanvasStyle
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onImportPDF: () -> Void
    let onExport: () -> Void

    @State private var position: CGPoint = CGPoint(x: 200, y: 60)
    @State private var isDragging = false
    @State private var showCanvasStylePicker = false

    var body: some View {
        HStack(spacing: 4) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 20)

            Divider()
                .frame(height: 20)

            // Undo / Redo
            toolButton(icon: "arrow.uturn.backward", action: onUndo)
            toolButton(icon: "arrow.uturn.forward", action: onRedo)

            Divider()
                .frame(height: 20)

            // Canvas style picker
            Button {
                showCanvasStylePicker.toggle()
            } label: {
                Image(systemName: canvasStyle.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .popover(isPresented: $showCanvasStylePicker) {
                canvasStylePopover
            }

            Divider()
                .frame(height: 20)

            // Import PDF
            toolButton(icon: "doc.badge.plus", action: onImportPDF)

            // Export
            toolButton(icon: "square.and.arrow.up", action: onExport)
        }
        .floatingPill()
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring()) {
                        isDragging = true
                        position = value.location
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isDragging = false
                    }
                }
        )
        .animation(.spring(response: 0.3), value: isDragging)
    }

    private func toolButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
    }

    private var canvasStylePopover: some View {
        VStack(spacing: 4) {
            ForEach(CanvasStyle.allCases) { style in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        canvasStyle = style
                    }
                    showCanvasStylePicker = false
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: style.icon)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 24)
                        Text(style.label)
                            .font(QuantaTheme.subheadline)
                        Spacer()
                        if canvasStyle == style {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.accentColor)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .frame(width: 180)
        .presentationCompactAdaptation(.popover)
    }
}
