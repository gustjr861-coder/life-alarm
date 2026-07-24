import SwiftUI

/// Telegram · Render 서버 설정 / 테스트
struct TelegramSettingsView: View {
    @ObservedObject var viewModel: ReminderViewModel

    @State private var chatID: String = StorageManager.telegramChatID
    @State private var serverURL: String = StorageManager.serverBaseURL
    @State private var statusText: String = ""
    @State private var isBusy = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Bot Token") {
                    Text(AppConfig.telegramBotToken.isEmpty ? "미설정" : "설정됨 ✓")
                        .foregroundStyle(AppConfig.telegramBotToken.isEmpty ? .red : .green)
                }
                Text("Token은 Secrets.plist 에만 넣고 Git에 올리지 마세요.\nSecrets.example.plist 를 복사해 Secrets.plist 로 사용합니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Telegram Bot")
            }

            Section("Chat ID") {
                TextField("예: 123456789", text: $chatID)
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button("Chat ID 저장") {
                    StorageManager.telegramChatID = chatID.trimmingCharacters(in: .whitespacesAndNewlines)
                    statusText = "Chat ID가 저장되었습니다."
                }
            }

            Section("Render 서버") {
                TextField("https://xxxx.onrender.com", text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Button("서버 URL 저장") {
                    let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    StorageManager.serverBaseURL = trimmed
                    serverURL = trimmed
                    statusText = "서버 URL이 저장되었습니다."
                }
            }

            Section("테스트") {
                Button {
                    Task { await runTelegramTest() }
                } label: {
                    Label("Telegram 테스트 메시지 보내기", systemImage: "paperplane.fill")
                }
                .disabled(isBusy)

                Button {
                    Task { await runServerHealth() }
                } label: {
                    Label("서버 Health 확인", systemImage: "heart.text.square")
                }
                .disabled(isBusy)

                Button {
                    Task { await viewModel.syncToServer() }
                } label: {
                    Label("일정을 서버에 동기화", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isBusy || !AppConfig.isServerConfigured)
            }

            Section("안내") {
                Text("앱이 켜져 있을 때: 정확한 시각에 Telegram 전송\n앱이 꺼져 있을 때: Render 서버(node-cron)가 대신 전송")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let last = TelegramForegroundScheduler.shared.lastSentDescription {
                    Text("최근 포그라운드 전송: \(last)")
                        .font(.footnote)
                }

                if !statusText.isEmpty {
                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let toast = viewModel.toastMessage {
                    Text(toast)
                        .font(.footnote)
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationTitle("Telegram / 서버")
        .onAppear {
            chatID = StorageManager.telegramChatID.isEmpty ? AppConfig.telegramChatID : StorageManager.telegramChatID
            serverURL = StorageManager.serverBaseURL.isEmpty ? AppConfig.serverBaseURL : StorageManager.serverBaseURL
        }
    }

    private func runTelegramTest() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await TelegramManager.shared.sendTestMessage()
            statusText = "테스트 메시지를 보냈습니다. Telegram을 확인하세요."
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func runServerHealth() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let ok = try await ScheduleAPIClient.shared.healthCheck()
            statusText = ok ? "서버 정상 응답" : "서버 응답 이상"
        } catch {
            statusText = error.localizedDescription
        }
    }
}
