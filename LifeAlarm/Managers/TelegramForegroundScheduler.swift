import Foundation

/// 앱이 포그라운드(실행 중)일 때 정각에 Telegram 자동 전송
@MainActor
final class TelegramForegroundScheduler: ObservableObject {
    static let shared = TelegramForegroundScheduler()

    @Published private(set) var lastSentDescription: String?

    private var timer: Timer?
    private var reminders: [Reminder] = []
    private let defaults = UserDefaults.standard
    private let sentKeyPrefix = "telegram_sent_"

    private init() {}

    func start(with reminders: [Reminder]) {
        self.reminders = reminders
        timer?.invalidate()

        // 15초마다 검사 → 분 단위 정각 전송
        let timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        Task { await tick() }
    }

    func updateReminders(_ reminders: [Reminder]) {
        self.reminders = reminders
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() async {
        guard AppConfig.isTelegramConfigured else { return }

        let now = Date()
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: now)

        for reminder in reminders where reminder.isEnabled {
            guard matches(reminder: reminder, components: comps, calendar: calendar) else { continue }
            guard !reminder.isCompleted(on: now, calendar: calendar) else { continue }

            let stamp = sentStamp(for: reminder.id, components: comps)
            if defaults.bool(forKey: stamp) { continue }

            do {
                try await TelegramManager.shared.sendReminder(reminder)
                defaults.set(true, forKey: stamp)
                lastSentDescription = "\(reminder.title) · \(RepeatRule.formatTime(hour: comps.hour ?? 0, minute: comps.minute ?? 0))"
                print("[TelegramForegroundScheduler] 전송 완료: \(reminder.title)")
            } catch {
                print("[TelegramForegroundScheduler] 전송 실패: \(error.localizedDescription)")
            }
        }
    }

    private func matches(reminder: Reminder, components: DateComponents, calendar: Calendar) -> Bool {
        let rule = reminder.repeatRule
        guard components.hour == rule.hour, components.minute == rule.minute else {
            return false
        }

        switch rule.kind {
        case .daily:
            return true
        case .weekly:
            guard let weekday = components.weekday else { return false }
            return rule.weekdays.contains(weekday)
        case .monthly:
            return components.day == rule.dayOfMonth
        case .yearly:
            return components.month == rule.monthOfYear && components.day == rule.dayOfYear
        }
    }

    private func sentStamp(for id: UUID, components: DateComponents) -> String {
        let y = components.year ?? 0
        let m = components.month ?? 0
        let d = components.day ?? 0
        let h = components.hour ?? 0
        let min = components.minute ?? 0
        return "\(sentKeyPrefix)\(id.uuidString)_\(y)\(m)\(d)_\(h)\(min)"
    }
}
