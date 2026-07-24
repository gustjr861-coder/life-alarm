import Foundation
import SwiftUI

/// 반복 규칙
enum RepeatKind: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "매일"
        case .weekly: return "매주"
        case .monthly: return "매달"
        case .yearly: return "매년"
        }
    }

    var systemImage: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar"
        case .monthly: return "calendar.badge.clock"
        case .yearly: return "gift.fill"
        }
    }
}

/// 알림 하나의 반복 설정
struct RepeatRule: Codable, Equatable, Hashable {
    var kind: RepeatKind

    /// 매주: Calendar weekday (1=일 ... 7=토), 복수 선택 가능
    var weekdays: [Int]

    /// 매달: 1~31
    var dayOfMonth: Int

    /// 매년: 월(1~12), 일(1~31)
    var monthOfYear: Int
    var dayOfYear: Int

    /// 시/분 (24시간)
    var hour: Int
    var minute: Int

    init(
        kind: RepeatKind = .monthly,
        weekdays: [Int] = [2], // 월요일
        dayOfMonth: Int = 7,
        monthOfYear: Int = 1,
        dayOfYear: Int = 1,
        hour: Int = 8,
        minute: Int = 0
    ) {
        self.kind = kind
        self.weekdays = weekdays.sorted()
        self.dayOfMonth = min(max(dayOfMonth, 1), 31)
        self.monthOfYear = min(max(monthOfYear, 1), 12)
        self.dayOfYear = min(max(dayOfYear, 1), 31)
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    /// 기본: 매달 7일 오전 8시 (Telegram 월세 알림)
    static var defaultMonthlyRent: RepeatRule {
        RepeatRule(kind: .monthly, dayOfMonth: 7, hour: 8, minute: 0)
    }

    /// 사람이 읽기 쉬운 요약
    var summaryText: String {
        let time = Self.formatTime(hour: hour, minute: minute)
        switch kind {
        case .daily:
            return "매일 \(time)"
        case .weekly:
            let days = weekdays.map { Self.weekdayName($0) }.joined(separator: ", ")
            return "매주 \(days) \(time)"
        case .monthly:
            return "매달 \(dayOfMonth)일 \(time)"
        case .yearly:
            return "매년 \(monthOfYear)월 \(dayOfYear)일 \(time)"
        }
    }

    static func weekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "일"
        case 2: return "월"
        case 3: return "화"
        case 4: return "수"
        case 5: return "목"
        case 6: return "금"
        case 7: return "토"
        default: return "?"
        }
    }

    static func formatTime(hour: Int, minute: Int) -> String {
        let period = hour < 12 ? "오전" : "오후"
        var display = hour % 12
        if display == 0 { display = 12 }
        return "\(period) \(display):\(String(format: "%02d", minute))"
    }
}
