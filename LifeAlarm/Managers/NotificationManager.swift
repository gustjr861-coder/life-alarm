import Foundation
import UserNotifications
import UIKit
import WidgetKit

/// 로컬 알림 예약 / 취소 / 권한 / 배지
@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    /// 미리 쌓아 둘 회차 수 (앱을 오래 안 열어도 반복 유지)
    private let lookaheadCount = 12

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
        super.init()
    }

    func configure() {
        center.delegate = self
        registerCategories()
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Permission

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            print("[NotificationManager] 권한 요청 실패: \(error)")
            await refreshAuthorizationStatus()
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Categories

    private func registerCategories() {
        let complete = UNNotificationAction(
            identifier: AppConstants.completeActionID,
            title: "오늘 완료",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: AppConstants.notificationCategoryID,
            actions: [complete],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Schedule

    /// 다음 N회차를 원샷으로 미리 예약 (완료 스킵·장기 미실행 대응)
    func scheduleNext(for reminder: Reminder) async {
        await cancel(id: reminder.id)

        guard reminder.isEnabled else {
            await updateBadge(with: StorageManager.loadReminders())
            return
        }

        var cursor = Date()
        var scheduled = 0

        for index in 0..<lookaheadCount {
            guard let fireDate = reminder.nextFireDate(after: cursor) else { break }

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.categoryIdentifier = AppConstants.notificationCategoryID
            content.userInfo = [
                "reminderID": reminder.id.uuidString,
                "occurrence": index
            ]

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: occurrenceID(reminderID: reminder.id, index: index),
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                scheduled += 1
            } catch {
                print("[NotificationManager] 예약 실패(\(index)): \(error)")
            }

            // 다음 탐색은 이번 fire 직후부터
            cursor = fireDate.addingTimeInterval(1)
        }

        print("[NotificationManager] \(reminder.title) \(scheduled)회 예약")
        await updateBadge(with: StorageManager.loadReminders())
        WidgetCenter.shared.reloadAllTimelines()
    }

    func rescheduleAll(_ reminders: [Reminder]) async {
        for reminder in reminders {
            await cancel(id: reminder.id)
        }

        for reminder in reminders where reminder.isEnabled {
            await scheduleNext(for: reminder)
        }

        await updateBadge(with: reminders)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func cancel(id: UUID) async {
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()

        let prefix = id.uuidString
        let pendingIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        let deliveredIDs = delivered
            .map(\.request.identifier)
            .filter { $0.hasPrefix(prefix) }

        center.removePendingNotificationRequests(withIdentifiers: pendingIDs)
        center.removeDeliveredNotifications(withIdentifiers: deliveredIDs)

        // 하위 호환: 예전 단일 ID 형식
        center.removePendingNotificationRequests(withIdentifiers: [prefix])
        center.removeDeliveredNotifications(withIdentifiers: [prefix])
    }

    private func occurrenceID(reminderID: UUID, index: Int) -> String {
        "\(reminderID.uuidString)_\(index)"
    }

    /// 즉시 테스트 알림 (3초 후)
    func sendTestNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: "life_alarm_test_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("[NotificationManager] 테스트 실패: \(error)")
        }
    }

    // MARK: - Badge

    func pendingTodayBadgeCount(reminders: [Reminder]) -> Int {
        reminders.filter { $0.isDueToday() }.count
    }

    func updateBadge(with reminders: [Reminder]) async {
        let count = pendingTodayBadgeCount(reminders: reminders)
        do {
            try await center.setBadgeCount(count)
        } catch {
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = count
            }
        }
    }
}

// MARK: - Delegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// 포그라운드에서도 배너·알림센터 표시
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound, .badge]
    }

    /// 알림 탭 / 액션
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let idString = userInfo["reminderID"] as? String,
              let id = UUID(uuidString: idString) else {
            return
        }

        await MainActor.run {
            NotificationCenter.default.post(
                name: .lifeAlarmNotificationAction,
                object: nil,
                userInfo: [
                    "reminderID": id,
                    "action": response.actionIdentifier
                ]
            )
        }
    }
}

extension Notification.Name {
    static let lifeAlarmNotificationAction = Notification.Name("lifeAlarmNotificationAction")
}
