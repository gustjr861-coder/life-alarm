import SwiftUI

/// 전체 알림 목록 (검색 / 정렬 / 수정 / 삭제)
struct AllRemindersView: View {
    @ObservedObject var viewModel: ReminderViewModel
    @State private var editingReminder: Reminder?
    @State private var creating = false

    var body: some View {
        List {
            ForEach(viewModel.filteredReminders) { reminder in
                ReminderCardView(
                    reminder: reminder,
                    showsCompleteButton: false,
                    onToggle: { viewModel.toggleEnabled(reminder) },
                    onTap: { editingReminder = reminder }
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            viewModel.delete(reminder)
                        }
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        editingReminder = reminder
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .contextMenu {
                    Button {
                        editingReminder = reminder
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    Button {
                        viewModel.sendTestNotification(for: reminder)
                    } label: {
                        Label("로컬 알림 테스트", systemImage: "bell.and.waves.left.and.right")
                    }
                    Button {
                        viewModel.sendTelegramTest(for: reminder)
                    } label: {
                        Label("Telegram 보내기", systemImage: "paperplane.fill")
                    }
                    Button(role: .destructive) {
                        viewModel.delete(reminder)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.lifeGroupedBackground)
        .searchable(text: $viewModel.searchText, prompt: "제목 검색")
        .overlay {
            if viewModel.filteredReminders.isEmpty {
                EmptyStateView(
                    title: viewModel.searchText.isEmpty ? "알림이 없습니다" : "검색 결과 없음",
                    message: viewModel.searchText.isEmpty
                        ? "오른쪽 위 + 버튼으로 새 알림을 추가하세요."
                        : "다른 검색어를 입력해 보세요.",
                    systemImage: "magnifyingglass"
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("정렬", selection: Binding(
                        get: { viewModel.sortOption },
                        set: { viewModel.applySort($0) }
                    )) {
                        ForEach(SortOption.allCases) { option in
                            Label(option.title, systemImage: option.systemImage)
                                .tag(option)
                        }
                    }
                } label: {
                    Label("정렬", systemImage: "arrow.up.arrow.down")
                }
            }

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
}
