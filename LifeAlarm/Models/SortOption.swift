import Foundation

/// 목록 정렬 옵션
enum SortOption: String, Codable, CaseIterable, Identifiable {
    case byDate
    case byName
    case byCreated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .byDate: return "날짜순"
        case .byName: return "가나다순"
        case .byCreated: return "생성순"
        }
    }

    var systemImage: String {
        switch self {
        case .byDate: return "calendar"
        case .byName: return "textformat.abc"
        case .byCreated: return "clock"
        }
    }
}
