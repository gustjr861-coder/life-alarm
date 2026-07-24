import Foundation

extension Date {
    /// 상대 표기: 오늘 / 내일 / M월 d일 오전 h:mm
    func lifeAlarmRelativeString(calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(self) {
            return "오늘 \(timeOnlyString())"
        }
        if calendar.isDateInTomorrow(self) {
            return "내일 \(timeOnlyString())"
        }

        let day = formatted(.dateTime.month().day().locale(Locale(identifier: "ko_KR")))
        return "\(day) \(timeOnlyString())"
    }

    func timeOnlyString() -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: self)
        let minute = calendar.component(.minute, from: self)
        return RepeatRule.formatTime(hour: hour, minute: minute)
    }

    var startOfDayValue: Date {
        Calendar.current.startOfDay(for: self)
    }
}
