import SwiftUI

/// 알림 카드 한 장
struct ReminderCardView: View {
    let reminder: Reminder
    var showsCompleteButton: Bool = false
    var onComplete: (() -> Void)? = nil
    var onToggle: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(reminder.themeColor.color.opacity(0.18))
                        .frame(width: 48, height: 48)
                    Image(systemName: reminder.icon.rawValue)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(reminder.themeColor.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reminder.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if !reminder.isEnabled {
                            Text("꺼짐")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.secondary.opacity(0.2)))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(reminder.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: reminder.repeatRule.kind.systemImage)
                        Text(reminder.repeatRule.summaryText)
                        if let next = reminder.nextFireDate() {
                            Text("·")
                            Text(next.lifeAlarmRelativeString())
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if showsCompleteButton {
                    Button {
                        onComplete?()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("오늘 완료")
                } else if let onToggle {
                    Toggle("", isOn: Binding(
                        get: { reminder.isEnabled },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}
