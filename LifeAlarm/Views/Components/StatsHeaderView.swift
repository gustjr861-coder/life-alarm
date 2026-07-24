import SwiftUI

struct StatsHeaderView: View {
    let activeCount: Int
    let dueTodayCount: Int

    var body: some View {
        HStack(spacing: 12) {
            statCard(
                title: "활성 알림",
                value: "\(activeCount)",
                icon: "bell.badge.fill",
                color: .blue
            )
            statCard(
                title: "오늘 할 일",
                value: "\(dueTodayCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
