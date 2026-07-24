import Foundation
import Combine
import UserNotifications
import WidgetKit

/// 알림 CRUD, 검색/정렬, 완료 처리, Telegram·서버 동기화
@MainActor
final class ReminderViewModel: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = StorageManager.sortOption
    @Published var toastMessage: String?
    @Published var isSyncing = false

    private let notifications = NotificationManager.shared
    private let telegramScheduler = TelegramForegroundScheduler.shared
    private var actionObserver: NSObjectProtocol?

    init() {
        reminders = StorageManager.loadReminders()
        observeNotificationActions()
    }

    deinit {
        if let actionObserver {
            NotificationCenter.default.removeObserver(actionObserver)
        }
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        notifications.configure()
        let granted = await notifications.requestAuthorization()

        if !StorageManager.didCompleteFirstLaunch {
            if reminders.isEmpty {
                reminders = [Reminder.sampleRent]
                persist()
            }
            StorageManager.didCompleteFirstLaunch = true
        }

        if granted || notifications.isAuthorized {
            await notifications.rescheduleAll(reminders)
        } else {
            await notifications.updateBadge(with: reminders)
        }

        telegramScheduler.start(with: reminders)

        // 서버가 설정돼 있으면 백그라운드용으로 전체 동기화
        if AppConfig.isServerConfigured {
            await syncToServer(silent: true)
        }
    }

    func refreshForegroundScheduler() {
        telegramScheduler.updateReminders(reminders)
    }

    // MARK: - Derived lists

    var filteredReminders: [Reminder] {
        let base: [Reminder]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            base = reminders
        } else {
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            base = reminders.filter {
                $0.title.localizedCaseInsensitiveContains(q)
                    || $0.body.localizedCaseInsensitiveContains(q)
            }
        }
        return sorted(base)
    }

    var todayReminders: [Reminder] {
        sorted(reminders.filter { $0.isDueToday() })
    }

    var upcomingReminders: [Reminder] {
        sorted(reminders.filter { DateCalculator.isUpcoming(reminder: $0, withinDays: 14) })
    }

    var activeCount: Int {
        reminders.filter(\.isEnabled).count
    }

    var dueTodayCount: Int {
        todayReminders.count
    }

    // MARK: - CRUD

    func add(_ reminder: Reminder) {
        reminders.insert(reminder, at: 0)
        persistAndPropagate()
        Task {
            await notifications.scheduleNext(for: reminder)
            await pushCreate(reminder)
            showToast("알림이 추가되었습니다")
        }
    }

    func update(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index] = reminder
        persistAndPropagate()
        Task {
            await notifications.scheduleNext(for: reminder)
            await pushUpdate(reminder)
            showToast("알림이 수정되었습니다")
        }
    }

    func delete(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        persistAndPropagate()
        Task {
            await notifications.cancel(id: reminder.id)
            await notifications.updateBadge(with: reminders)
            WidgetCenter.shared.reloadAllTimelines()
            await pushDelete(reminder.id)
            showToast("알림이 삭제되었습니다")
        }
    }

    func delete(at offsets: IndexSet, in list: [Reminder]) {
        for index in offsets {
            delete(list[index])
        }
    }

    func toggleEnabled(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].isEnabled.toggle()
        let updated = reminders[index]
        persistAndPropagate()
        Task {
            await notifications.scheduleNext(for: updated)
            await pushUpdate(updated)
            showToast(updated.isEnabled ? "알림이 켜졌습니다" : "알림이 꺼졌습니다")
        }
    }

    func completeToday(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].lastCompletedDate = Date()
        let updated = reminders[index]
        persistAndPropagate()
        Task {
            await notifications.scheduleNext(for: updated)
            showToast("오늘 완료 처리되었습니다")
        }
    }

    func undoCompleteToday(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        reminders[index].lastCompletedDate = nil
        let updated = reminders[index]
        persistAndPropagate()
        Task {
            await notifications.scheduleNext(for: updated)
            showToast("완료를 취소했습니다")
        }
    }

    func applySort(_ option: SortOption) {
        sortOption = option
        StorageManager.sortOption = option
    }

    func sendTestNotification(for reminder: Reminder) {
        Task {
            guard notifications.isAuthorized else {
                showToast("알림 권한이 필요합니다")
                return
            }
            await notifications.sendTestNotification(title: reminder.title, body: reminder.body)
            showToast("3초 후 테스트 알림이 옵니다")
        }
    }

    func sendGenericTestNotification() {
        Task {
            guard notifications.isAuthorized else {
                _ = await notifications.requestAuthorization()
                if !notifications.isAuthorized {
                    showToast("알림 권한이 필요합니다")
                    return
                }
            }
            await notifications.sendTestNotification(
                title: "생활 알림",
                body: "테스트 알림입니다. 정상 동작 중입니다."
            )
            showToast("3초 후 테스트 알림이 옵니다")
        }
    }

    func sendTelegramTest(for reminder: Reminder) {
        Task {
            do {
                try await TelegramManager.shared.sendReminder(reminder)
                showToast("Telegram으로 보냈습니다")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    func syncToServer(silent: Bool = false) async {
        guard AppConfig.isServerConfigured else {
            if !silent { showToast("서버 URL을 먼저 설정하세요") }
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            try await ScheduleAPIClient.shared.syncAll(reminders)
            if !silent { showToast("서버 동기화 완료") }
        } catch {
            if !silent { showToast(error.localizedDescription) }
            print("[ReminderViewModel] sync 실패: \(error)")
        }
    }

    // MARK: - Private

    private func sorted(_ list: [Reminder]) -> [Reminder] {
        switch sortOption {
        case .byName:
            return list.sorted {
                $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        case .byCreated:
            return list.sorted { $0.createdAt > $1.createdAt }
        case .byDate:
            return list.sorted {
                let lhs = $0.nextFireDate() ?? .distantFuture
                let rhs = $1.nextFireDate() ?? .distantFuture
                return lhs < rhs
            }
        }
    }

    private func persist() {
        StorageManager.saveReminders(reminders)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persistAndPropagate() {
        persist()
        telegramScheduler.updateReminders(reminders)
    }

    private func pushCreate(_ reminder: Reminder) async {
        guard AppConfig.isServerConfigured else { return }
        do {
            _ = try await ScheduleAPIClient.shared.createSchedule(reminder.asScheduleDTO)
        } catch {
            // 단건 실패 시 전체 sync로 보정
            await syncToServer(silent: true)
        }
    }

    private func pushUpdate(_ reminder: Reminder) async {
        guard AppConfig.isServerConfigured else { return }
        do {
            _ = try await ScheduleAPIClient.shared.updateSchedule(reminder.asScheduleDTO)
        } catch {
            await syncToServer(silent: true)
        }
    }

    private func pushDelete(_ id: UUID) async {
        guard AppConfig.isServerConfigured else { return }
        do {
            try await ScheduleAPIClient.shared.deleteSchedule(id: id.uuidString)
        } catch {
            await syncToServer(silent: true)
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    private func observeNotificationActions() {
        actionObserver = NotificationCenter.default.addObserver(
            forName: .lifeAlarmNotificationAction,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let id = note.userInfo?["reminderID"] as? UUID else { return }
            let action = note.userInfo?["action"] as? String ?? ""

            Task { @MainActor in
                guard let reminder = self.reminders.first(where: { $0.id == id }) else { return }
                if action == AppConstants.completeActionID {
                    self.completeToday(reminder)
                }
            }
        }
    }
}
