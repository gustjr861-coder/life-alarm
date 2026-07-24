import Foundation

/// 반복 규칙 기반 다음 발생일 / 오늘 여부 계산
enum DateCalculator {
    /// 해당 날짜가 반복 규칙상 예정일인지 (시각은 무시하고 날짜/요일만)
    static func isScheduled(
        reminder: Reminder,
        on day: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let rule = reminder.repeatRule
        let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: day)

        switch rule.kind {
        case .daily:
            return true
        case .weekly:
            guard let weekday = comps.weekday else { return false }
            return rule.weekdays.contains(weekday)
        case .monthly:
            return comps.day == rule.dayOfMonth
        case .yearly:
            return comps.month == rule.monthOfYear && comps.day == rule.dayOfYear
        }
    }

    /// `after` 이후(초과) 다음 알림 시각.
    /// 오늘 완료된 경우 오늘 슬롯은 건너뛴다.
    static func nextFireDate(
        for reminder: Reminder,
        after date: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        guard reminder.isEnabled else { return nil }

        let rule = reminder.repeatRule
        let completedToday = reminder.isCompleted(on: date, calendar: calendar)

        // 최대 400일 앞까지 탐색 (윤년/31일 등 안전)
        for offset in 0..<400 {
            guard let candidateDay = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) else {
                continue
            }

            guard isScheduled(reminder: reminder, on: candidateDay, calendar: calendar) else {
                continue
            }

            // 오늘 완료면 오늘 날짜 슬롯 스킵
            if completedToday && calendar.isDate(candidateDay, inSameDayAs: date) {
                continue
            }

            var comps = calendar.dateComponents([.year, .month, .day], from: candidateDay)
            comps.hour = rule.hour
            comps.minute = rule.minute
            comps.second = 0

            guard let fire = calendar.date(from: comps) else { continue }

            // after 이후만 (같은 시각 이전이면 다음 사이클로)
            if fire > date {
                return fire
            }

            // 같은 날인데 이미 시각이 지났으면 다음 사이클로 계속
            if calendar.isDate(candidateDay, inSameDayAs: date) {
                continue
            }
        }

        return nil
    }

    /// 다가오는 일정용: 다음 발생이 `withinDays` 이내인지
    static func isUpcoming(
        reminder: Reminder,
        withinDays: Int = 7,
        calendar: Calendar = .current
    ) -> Bool {
        guard reminder.isEnabled else { return false }
        guard let next = nextFireDate(for: reminder, after: Date(), calendar: calendar) else {
            return false
        }
        guard let limit = calendar.date(byAdding: .day, value: withinDays, to: Date()) else {
            return false
        }
        // 오늘은 '오늘 할 일'로 분리하므로 다가오기에선 제외
        if calendar.isDateInToday(next) {
            return false
        }
        return next <= limit
    }
}
