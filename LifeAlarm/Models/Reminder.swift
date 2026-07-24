import Foundation

/// 생활 알림 한 건
struct Reminder: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var body: String
    var repeatRule: RepeatRule
    var isEnabled: Bool
    var themeColor: ReminderThemeColor
    var icon: ReminderIcon
    var createdAt: Date

    /// 오늘 완료 처리한 날짜 (해당 캘린더 날짜만 비교)
    var lastCompletedDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        repeatRule: RepeatRule = .defaultMonthlyRent,
        isEnabled: Bool = true,
        themeColor: ReminderThemeColor = .blue,
        icon: ReminderIcon = .bell,
        createdAt: Date = Date(),
        lastCompletedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.repeatRule = repeatRule
        self.isEnabled = isEnabled
        self.themeColor = themeColor
        self.icon = icon
        self.createdAt = createdAt
        self.lastCompletedDate = lastCompletedDate
    }

    /// 첫 실행 기본 샘플: 월세
    static var sampleRent: Reminder {
        Reminder(
            title: "월세",
            body: "김현석 월세 내는 날입니다.",
            repeatRule: .defaultMonthlyRent,
            isEnabled: true,
            themeColor: .blue,
            icon: .house
        )
    }

    /// 오늘 이미 완료했는지
    func isCompleted(on day: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let lastCompletedDate else { return false }
        return calendar.isDate(lastCompletedDate, inSameDayAs: day)
    }

    /// 오늘 일정에 해당하는지 (반복 규칙상 오늘이 예정일)
    func isScheduled(on day: Date = Date(), calendar: Calendar = .current) -> Bool {
        DateCalculator.isScheduled(reminder: self, on: day, calendar: calendar)
    }

    /// 오늘 해야 할 일 (활성 + 오늘 예정 + 미완료)
    func isDueToday(calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }
        guard isScheduled(on: Date(), calendar: calendar) else { return false }
        return !isCompleted(on: Date(), calendar: calendar)
    }

    /// 다음 알림 시각 (완료 스킵 반영)
    func nextFireDate(after date: Date = Date(), calendar: Calendar = .current) -> Date? {
        DateCalculator.nextFireDate(for: self, after: date, calendar: calendar)
    }
}
