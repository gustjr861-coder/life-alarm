import SwiftUI

/// 홈: 오늘 / 다가오는 / 통계 / 전체 바로가기
struct HomeView: View {
    @ObservedObject var viewModel: ReminderViewModel
    @State private var creating = false
    @State private var editingReminder: Reminder?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PermissionBannerView()

                StatsHeaderView(
                    activeCount: viewModel.activeCount,
                    dueTodayCount: viewModel.dueTodayCount
                )

                todaySection
                upcomingSection
                allPreviewSection

                Button {
                    viewModel.sendGenericTestNotification()
                } label: {
                    Label("로컬 알림 테스트", systemImage: "bell.and.waves.left.and.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button {
                    if let first = viewModel.reminders.first {
                        viewModel.sendTelegramTest(for: first)
                    }
                } label: {
                    Label("Telegram 테스트", systemImage: "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.reminders.isEmpty)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color.lifeGroupedBackground.ignoresSafeArea())
        .navigationTitle(AppConstants.appName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    creating = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("알림 추가")
            }
        }
        .sheet(isPresented: $creating) {
            NavigationStack {
                ReminderFormView(mode: .create, viewModel: viewModel)
            }
        }
        .sheet(item: $editingReminder) { reminder in
            NavigationStack {
                ReminderFormView(mode: .edit(reminder), viewModel: viewModel)
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "오늘 해야 할 일", icon: "sun.max.fill")

            if viewModel.todayReminders.isEmpty {
                EmptyStateView(
                    title: "오늘은 여유롭네요",
                    message: "오늘 예정된 미완료 알림이 없습니다.",
                    systemImage: "checkmark.seal"
                )
                .lifeCardStyle()
            } else {
                ForEach(viewModel.todayReminders) { reminder in
                    ReminderCardView(
                        reminder: reminder,
                        showsCompleteButton: true,
                        onComplete: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.completeToday(reminder)
                            }
                        },
                        onTap: { editingReminder = reminder }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
        }
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "다가오는 일정", icon: "calendar")

            if viewModel.upcomingReminders.isEmpty {
                EmptyStateView(
                    title: "다가오는 일정 없음",
                    message: "앞으로 2주 안에 울릴 알림이 없습니다.",
                    systemImage: "calendar.badge.clock"
                )
                .lifeCardStyle()
            } else {
                ForEach(viewModel.upcomingReminders.prefix(8)) { reminder in
                    ReminderCardView(
                        reminder: reminder,
                        onTap: { editingReminder = reminder }
                    )
                }
            }
        }
    }

    private var allPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "전체 알림", icon: "list.bullet")

            ForEach(viewModel.filteredReminders.prefix(5)) { reminder in
                ReminderCardView(
                    reminder: reminder,
                    onToggle: { viewModel.toggleEnabled(reminder) },
                    onTap: { editingReminder = reminder }
                )
                .contextMenu {
                    Button { editingReminder = reminder } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        viewModel.delete(reminder)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }

            if viewModel.reminders.isEmpty {
                EmptyStateView(
                    title: "알림을 추가하세요",
                    message: "월세, 카드값, 약 먹기 등 반복 일정을 등록할 수 있습니다.",
                    systemImage: "plus.circle"
                )
                .lifeCardStyle()
            }
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.title3.weight(.bold))
            .padding(.top, 4)
    }
}
