import SwiftUI

struct CanvasToolbar: View {
    @Binding var selectedTool: CanvasTool
    @Binding var selectedColor: Color
    let onUndo: () -> Void
    let onRedo: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Drawing tools
            HStack(spacing: 2) {
                toolButton(.pen)
                toolButton(.highlighter)
                toolButton(.eraser)
                toolButton(.lasso)
            }

            divider

            // Color picker
            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 30, height: 30)
                .padding(.horizontal, 12)

            divider

            // Undo / Redo
            HStack(spacing: 2) {
                actionButton(icon: "arrow.uturn.backward", action: onUndo)
                actionButton(icon: "arrow.uturn.forward", action: onRedo)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(QuantaTheme.toolbarBg)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 28)
            .padding(.horizontal, 4)
    }

    private func toolButton(_ tool: CanvasTool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTool = tool
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tool.icon)
                    .font(.system(size: 17, weight: .medium))
                    .frame(height: 22)

                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 20, height: 2.5)
                    .opacity(selectedTool == tool ? 1 : 0)
            }
            .foregroundStyle(selectedTool == tool ? QuantaTheme.gold : .white.opacity(0.5))
            .frame(width: 50, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 44, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
