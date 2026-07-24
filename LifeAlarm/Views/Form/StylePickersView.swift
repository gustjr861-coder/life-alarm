import SwiftUI

/// 아이콘 그리드 선택
struct IconPickerView: View {
    @Binding var selection: ReminderIcon

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(ReminderIcon.allCases) { icon in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = icon
                    }
                } label: {
                    Image(systemName: icon.rawValue)
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 56, height: 56)
                        .foregroundStyle(selection == icon ? Color.white : Color.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selection == icon ? Color.accentColor : Color(.tertiarySystemFill))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(icon.title)
            }
        }
    }
}

/// 색상 선택 가로 스크롤
struct ColorPickerRow: View {
    @Binding var selection: ReminderThemeColor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ReminderThemeColor.allCases) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = theme
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.color)
                                .frame(width: 34, height: 34)
                            if selection == theme {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(theme.title)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
