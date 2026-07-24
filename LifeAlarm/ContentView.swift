import SwiftUI

/// 루트: 홈 + 목록 + Telegram 설정
struct ContentView: View {
    @StateObject private var viewModel = ReminderViewModel()
    @ObservedObject private var notificationManager = NotificationManager.shared

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(viewModel: viewModel)
            }
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }

            NavigationStack {
                AllRemindersView(viewModel: viewModel)
                    .navigationTitle("전체 알림")
            }
            .tabItem {
                Label("목록", systemImage: "list.bullet")
            }

            NavigationStack {
                TelegramSettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Telegram", systemImage: "paperplane.fill")
            }
        }
        .task {
            await viewModel.bootstrap()
            await notificationManager.refreshAuthorizationStatus()
        }
        .overlay(alignment: .bottom) {
            if let message = viewModel.toastMessage {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35), value: viewModel.toastMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
