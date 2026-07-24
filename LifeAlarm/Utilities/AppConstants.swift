import Foundation

/// 앱 전역 상수
enum AppConstants {
    /// 표시 이름
    static let appName = "생활 알림"

    /// UserDefaults / App Group 키
    static let remindersStorageKey = "life_alarm_reminders_v1"
    static let firstLaunchKey = "life_alarm_first_launch_done"
    static let sortOptionKey = "life_alarm_sort_option"

    /// App Group (앱 ↔ 위젯 데이터 공유)
    /// Xcode Signing & Capabilities에서 동일 식별자로 App Groups를 추가해야 합니다.
    static let appGroupID = "group.com.personal.lifealarm"

    /// 알림 카테고리
    static let notificationCategoryID = "LIFE_ALARM_CATEGORY"
    static let completeActionID = "COMPLETE_TODAY_ACTION"

    /// Telegram / Render (UserDefaults 키 — 값은 Secrets.plist 또는 설정 화면)
    static let telegramChatIDKey = "life_alarm_telegram_chat_id"
    static let serverBaseURLKey = "life_alarm_server_base_url"
}
