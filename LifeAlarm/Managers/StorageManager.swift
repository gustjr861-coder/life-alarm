import Foundation

/// UserDefaults 래퍼 (앱 + 위젯 공용 App Group 우선)
enum StorageManager {
    static var store: UserDefaults {
        if let shared = UserDefaults(suiteName: AppConstants.appGroupID) {
            return shared
        }
        return .standard
    }

    static func loadReminders() -> [Reminder] {
        guard let data = store.data(forKey: AppConstants.remindersStorageKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([Reminder].self, from: data)
        } catch {
            print("[StorageManager] decode 실패: \(error)")
            return []
        }
    }

    static func saveReminders(_ reminders: [Reminder]) {
        do {
            let data = try JSONEncoder().encode(reminders)
            store.set(data, forKey: AppConstants.remindersStorageKey)
            store.synchronize()
        } catch {
            print("[StorageManager] encode 실패: \(error)")
        }
    }

    static var sortOption: SortOption {
        get {
            guard let raw = store.string(forKey: AppConstants.sortOptionKey),
                  let option = SortOption(rawValue: raw) else {
                return .byDate
            }
            return option
        }
        set {
            store.set(newValue.rawValue, forKey: AppConstants.sortOptionKey)
        }
    }

    static var didCompleteFirstLaunch: Bool {
        get { store.bool(forKey: AppConstants.firstLaunchKey) }
        set { store.set(newValue, forKey: AppConstants.firstLaunchKey) }
    }

    /// 설정 화면에서 저장한 Chat ID (Secrets.plist보다 우선)
    static var telegramChatID: String {
        get { UserDefaults.standard.string(forKey: AppConstants.telegramChatIDKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.telegramChatIDKey) }
    }

    /// Render 서버 Base URL
    static var serverBaseURL: String {
        get { UserDefaults.standard.string(forKey: AppConstants.serverBaseURLKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: AppConstants.serverBaseURLKey) }
    }
}
