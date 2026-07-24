import SwiftUI
import UserNotifications

@main
struct LifeAlarmApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                Task {
                    await NotificationManager.shared.refreshAuthorizationStatus()
                    let reminders = StorageManager.loadReminders()
                    await NotificationManager.shared.rescheduleAll(reminders)
                    TelegramForegroundScheduler.shared.start(with: reminders)
                }
            case .background, .inactive:
                // 백그라운드에서는 iOS 제약으로 정확한 Telegram 전송 불가 → Render 서버가 담당
                break
            @unknown default:
                break
            }
        }
    }
}
