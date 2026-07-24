import WidgetKit
import SwiftUI

/// 위젯/앱이 공유하는 오늘 할 일 스냅샷
struct TodayEntry: TimelineEntry {
    let date: Date
    let items: [WidgetReminderItem]
}

struct WidgetReminderItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let body: String
    let timeText: String
    let icon: String
    let colorName: String
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(
            date: Date(),
            items: [
                WidgetReminderItem(
                    id: UUID(),
                    title: "월세",
                    body: "김현석 월세 내는 날입니다.",
                    timeText: "오전 9:00",
                    icon: "house.fill",
                    colorName: "blue"
                )
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> TodayEntry {
        let reminders = StorageManager.loadReminders()
        let today = reminders
            .filter { $0.isDueToday() }
            .sorted {
                ($0.nextFireDate() ?? .distantFuture) < ($1.nextFireDate() ?? .distantFuture)
            }
            .prefix(5)
            .map { reminder in
                WidgetReminderItem(
                    id: reminder.id,
                    title: reminder.title,
                    body: reminder.body,
                    timeText: RepeatRule.formatTime(
                        hour: reminder.repeatRule.hour,
                        minute: reminder.repeatRule.minute
                    ),
                    icon: reminder.icon.rawValue,
                    colorName: reminder.themeColor.rawValue
                )
            }

        return TodayEntry(date: Date(), items: Array(today))
    }
}

struct TodayWidgetView: View {
    var entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("오늘 할 일", systemImage: "sun.max.fill")
                    .font(.headline)
                Spacer()
                Text("\(entry.items.count)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if entry.items.isEmpty {
                Spacer(minLength: 0)
                Text("오늘 예정된 알림이 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else {
                ForEach(entry.items.prefix(family == .systemSmall ? 2 : 4)) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .foregroundStyle(color(for: item.colorName))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            if family != .systemSmall {
                                Text(item.timeText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func color(for name: String) -> Color {
        ReminderThemeColor(rawValue: name)?.color ?? .blue
    }
}

struct LifeAlarmTodayWidget: Widget {
    let kind = "LifeAlarmTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("오늘 할 일")
        .description("오늘 완료하지 않은 생활 알림을 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LifeAlarmWidgetBundle: WidgetBundle {
    var body: some Widget {
        LifeAlarmTodayWidget()
    }
}
