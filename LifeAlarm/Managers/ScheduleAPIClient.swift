import Foundation

/// Render.com Express 서버 REST 클라이언트
actor ScheduleAPIClient {
    static let shared = ScheduleAPIClient()

    enum APIError: LocalizedError {
        case notConfigured
        case invalidURL
        case httpStatus(Int, String)
        case decodeFailed

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "SERVER_BASE_URL이 설정되지 않았습니다."
            case .invalidURL:
                return "서버 URL이 올바르지 않습니다."
            case .httpStatus(let code, let body):
                return "서버 오류 (\(code)): \(body)"
            case .decodeFailed:
                return "서버 응답을 해석하지 못했습니다."
            }
        }
    }

    private init() {}

    private var baseURL: String { AppConfig.serverBaseURL }

    func fetchSchedules() async throws -> [ScheduleDTO] {
        let data = try await request(path: "/schedule", method: "GET")
        do {
            return try JSONDecoder().decode([ScheduleDTO].self, from: data)
        } catch {
            throw APIError.decodeFailed
        }
    }

    func createSchedule(_ dto: ScheduleDTO) async throws -> ScheduleDTO {
        let data = try await request(path: "/schedule", method: "POST", body: dto)
        return try JSONDecoder().decode(ScheduleDTO.self, from: data)
    }

    func updateSchedule(_ dto: ScheduleDTO) async throws -> ScheduleDTO {
        let data = try await request(path: "/schedule/\(dto.id)", method: "PUT", body: dto)
        return try JSONDecoder().decode(ScheduleDTO.self, from: data)
    }

    func deleteSchedule(id: String) async throws {
        _ = try await request(path: "/schedule/\(id)", method: "DELETE")
    }

    /// 앱의 전체 일정을 서버에 동기화 (교체)
    func syncAll(_ reminders: [Reminder]) async throws {
        let payload = reminders.map { $0.asScheduleDTO }
        struct SyncBody: Codable { let schedules: [ScheduleDTO] }
        _ = try await request(path: "/sync", method: "POST", body: SyncBody(schedules: payload))
    }

    func healthCheck() async throws -> Bool {
        let data = try await request(path: "/health", method: "GET")
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ok = json["ok"] as? Bool {
            return ok
        }
        return true
    }

    // MARK: - Private

    private func request<Body: Encodable>(path: String, method: String, body: Body) async throws -> Data {
        let encoded = try JSONEncoder().encode(body)
        return try await request(path: path, method: method, rawBody: encoded)
    }

    private func request(path: String, method: String, rawBody: Data? = nil) async throws -> Data {
        guard !baseURL.isEmpty else { throw APIError.notConfigured }
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        if let rawBody {
            request.httpBody = rawBody
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.httpStatus(-1, "응답 없음")
        }

        let text = String(data: data, encoding: .utf8) ?? ""
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, text)
        }
        return data
    }
}
