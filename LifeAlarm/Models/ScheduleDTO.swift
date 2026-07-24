import Foundation

/// Render 서버와 주고하는 일정 DTO
struct ScheduleDTO: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
    var repeatKind: String
    var weekdays: [Int]
    var dayOfMonth: Int
    var monthOfYear: Int
    var dayOfYear: Int
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    init(from reminder: Reminder) {
        id = reminder.id.uuidString
        title = reminder.title
        body = reminder.body
        repeatKind = reminder.repeatRule.kind.rawValue
        weekdays = reminder.repeatRule.weekdays
        dayOfMonth = reminder.repeatRule.dayOfMonth
        monthOfYear = reminder.repeatRule.monthOfYear
        dayOfYear = reminder.repeatRule.dayOfYear
        hour = reminder.repeatRule.hour
        minute = reminder.repeatRule.minute
        isEnabled = reminder.isEnabled
    }

    /// 텔레그램 전송 문구
    var telegramMessage: String {
        "🔔 \(title) 알림\n\(body)"
    }
}

extension Reminder {
    var telegramMessage: String {
        "🔔 \(title) 알림\n\(body)"
    }

    var asScheduleDTO: ScheduleDTO {
        ScheduleDTO(from: self)
    }
}
