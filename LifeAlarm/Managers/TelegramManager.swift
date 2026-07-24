import Foundation

/// Telegram Bot API 전송
/// https://api.telegram.org/bot<TOKEN>/sendMessage
actor TelegramManager {
    static let shared = TelegramManager()

    enum TelegramError: LocalizedError {
        case notConfigured
        case invalidURL
        case httpStatus(Int, String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Telegram Bot Token 또는 Chat ID가 설정되지 않았습니다."
            case .invalidURL:
                return "Telegram API URL이 올바르지 않습니다."
            case .httpStatus(let code, let body):
                return "Telegram API 오류 (\(code)): \(body)"
            case .emptyResponse:
                return "Telegram 응답이 비어 있습니다."
            }
        }
    }

    private init() {}

    /// 임의 텍스트 전송
    @discardableResult
    func sendMessage(_ text: String) async throws -> Bool {
        let token = AppConfig.telegramBotToken
        let chatID = AppConfig.telegramChatID

        guard !token.isEmpty, !chatID.isEmpty else {
            throw TelegramError.notConfigured
        }

        guard let url = URL(string: "https://api.telegram.org/bot\(token)/sendMessage") else {
            throw TelegramError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let payload: [String: Any] = [
            "chat_id": chatID,
            "text": text,
            "disable_web_page_preview": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TelegramError.emptyResponse
        }

        let body = String(data: data, encoding: .utf8) ?? ""
        guard (200...299).contains(http.statusCode) else {
            throw TelegramError.httpStatus(http.statusCode, body)
        }

        return true
    }

    /// 일정 기반 표준 문구 전송
    func sendReminder(_ reminder: Reminder) async throws {
        try await sendMessage(reminder.telegramMessage)
    }

    func sendTestMessage() async throws {
        try await sendMessage("🔔 생활 알림 테스트\nTelegram 연결이 정상입니다.")
    }
}
