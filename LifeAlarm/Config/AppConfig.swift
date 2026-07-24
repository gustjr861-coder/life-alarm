import Foundation

/// Telegram / Render 서버 설정.
/// Bot Token · Chat ID 는 절대 소스에 하드코딩하지 않는다.
///
/// 우선순위:
/// 1) 번들 `Secrets.plist` (로컬 전용, gitignore)
/// 2) UserDefaults (설정 화면에서 Chat ID / Server URL 저장)
/// 3) 프로세스 환경변수 (CI/스킴용)
enum AppConfig {
    private static let secretsFileName = "Secrets"

    // MARK: - Telegram

    /// BotFather에서 발급받은 토큰
    static var telegramBotToken: String {
        if let value = string(fromSecrets: "TELEGRAM_BOT_TOKEN"), !value.isEmpty {
            return value
        }
        if let env = ProcessInfo.processInfo.environment["TELEGRAM_BOT_TOKEN"], !env.isEmpty {
            return env
        }
        return ""
    }

    /// 메시지를 받을 Chat ID
    static var telegramChatID: String {
        if let saved = UserDefaults.standard.string(forKey: AppConstants.telegramChatIDKey), !saved.isEmpty {
            return saved
        }
        if let value = string(fromSecrets: "TELEGRAM_CHAT_ID"), !value.isEmpty {
            return value
        }
        if let env = ProcessInfo.processInfo.environment["TELEGRAM_CHAT_ID"], !env.isEmpty {
            return env
        }
        return ""
    }

    // MARK: - Render API

    /// 예: https://life-alarm-xxxx.onrender.com
    static var serverBaseURL: String {
        if let saved = UserDefaults.standard.string(forKey: AppConstants.serverBaseURLKey), !saved.isEmpty {
            return saved.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        if let value = string(fromSecrets: "SERVER_BASE_URL"), !value.isEmpty {
            return value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        if let env = ProcessInfo.processInfo.environment["SERVER_BASE_URL"], !env.isEmpty {
            return env.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return ""
    }

    static var isTelegramConfigured: Bool {
        !telegramBotToken.isEmpty && !telegramChatID.isEmpty
    }

    static var isServerConfigured: Bool {
        !serverBaseURL.isEmpty
    }

    // MARK: - Secrets.plist

    private static var secretsDictionary: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: secretsFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        return dict
    }()

    private static func string(fromSecrets key: String) -> String? {
        secretsDictionary?[key] as? String
    }
}
