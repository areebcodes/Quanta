import SwiftUI

struct CanvasToolbar: View {
    @Binding var selectedTool: CanvasTool
    @Binding var selectedColor: Color
    @Binding var selectedSize: ToolSize
    let onUndo: () -> Void
    let onRedo: () -> Void

    @State private var showSizePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Size picker
            if showSizePicker && selectedTool != .lasso {
                sizePickerRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Main toolbar
            HStack(spacing: 0) {
                // Drawing tools
                HStack(spacing: 2) {
                    toolButton(.pen)
                    toolButton(.highlighter)
                    toolButton(.eraser)
                    toolButton(.lasso)
                }

                divider

                // Color swatches
                HStack(spacing: 6) {
                    ForEach(Array(ToolbarSwatch.allCases.filter { $0 != .custom }), id: \.self) { swatch in
                        Button {
                            selectedColor = swatch.color
                        } label: {
                            Circle()
                                .fill(swatch.color)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(QuantaTheme.gold, lineWidth: 2.5)
                                        .frame(width: 28, height: 28)
                                        .opacity(isColorSelected(swatch) ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        .opacity(selectedTool == .eraser || selectedTool == .lasso ? 0.35 : 1)
                    }

                    // Custom color picker
                    ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 22, height: 22)
                        .opacity(selectedTool == .eraser || selectedTool == .lasso ? 0.35 : 1)
                }
                .padding(.horizontal, 8)

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
    }

    // MARK: - Size Picker

    private var sizePickerRow: some View {
        HStack(spacing: 16) {
            ForEach(ToolSize.allCases, id: \.self) { size in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedSize = size
                    }
                } label: {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(selectedSize == size ? QuantaTheme.gold : .white.opacity(0.5))
                            .frame(width: size.dotSize, height: size.dotSize)
                        Text(size.label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(selectedSize == size ? QuantaTheme.gold : .white.opacity(0.4))
                    }
                    .frame(width: 56, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.08))
    }

    // MARK: - Components

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 28)
            .padding(.horizontal, 4)
    }

    private func toolButton(_ tool: CanvasTool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if selectedTool == tool {
                    showSizePicker.toggle()
                } else {
                    selectedTool = tool
                    showSizePicker = false
                }
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

    // MARK: - Helpers

    private func isColorSelected(_ swatch: ToolbarSwatch) -> Bool {
        let swatchComponents = UIColor(swatch.color).cgColor.components ?? []
        let selectedComponents = UIColor(selectedColor).cgColor.components ?? []
        guard swatchComponents.count >= 3, selectedComponents.count >= 3 else { return false }
        return abs(swatchComponents[0] - selectedComponents[0]) < 0.02
            && abs(swatchComponents[1] - selectedComponents[1]) < 0.02
            && abs(swatchComponents[2] - selectedComponents[2]) < 0.02
    }
}
