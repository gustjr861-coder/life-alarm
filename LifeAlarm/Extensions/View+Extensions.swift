import SwiftUI

extension View {
    /// 카드형 컨테이너
    func lifeCardStyle() -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }

    /// 조건부 modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension Color {
    /// Asset 없이도 쓰는 배경 보조색
    static var lifeGroupedBackground: Color {
        Color(.systemGroupedBackground)
    }
}
