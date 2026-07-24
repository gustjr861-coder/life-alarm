import Foundation
import SwiftUI

/// 카드/아이콘에 쓸 테마 색
enum ReminderThemeColor: String, Codable, CaseIterable, Identifiable {
    case blue
    case teal
    case green
    case orange
    case red
    case purple
    case pink
    case indigo
    case brown
    case gray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: return "파랑"
        case .teal: return "청록"
        case .green: return "초록"
        case .orange: return "주황"
        case .red: return "빨강"
        case .purple: return "보라"
        case .pink: return "분홍"
        case .indigo: return "남색"
        case .brown: return "갈색"
        case .gray: return "회색"
        }
    }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .teal: return .teal
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        case .indigo: return .indigo
        case .brown: return .brown
        case .gray: return .gray
        }
    }
}

/// 선택 가능한 SF Symbol 목록
enum ReminderIcon: String, Codable, CaseIterable, Identifiable {
    case bell = "bell.fill"
    case house = "house.fill"
    case card = "creditcard.fill"
    case shield = "shield.fill"
    case banknote = "banknote.fill"
    case building = "building.columns.fill"
    case car = "car.fill"
    case doc = "doc.text.fill"
    case cross = "cross.case.fill"
    case pills = "pills.fill"
    case figure = "figure.run"
    case gift = "gift.fill"
    case heart = "heart.fill"
    case star = "star.fill"
    case calendar = "calendar"
    case leaf = "leaf.fill"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bell: return "알림"
        case .house: return "집"
        case .card: return "카드"
        case .shield: return "보험"
        case .banknote: return "저축"
        case .building: return "대출"
        case .car: return "자동차"
        case .doc: return "세금"
        case .cross: return "병원"
        case .pills: return "약"
        case .figure: return "운동"
        case .gift: return "기념일"
        case .heart: return "하트"
        case .star: return "별"
        case .calendar: return "일정"
        case .leaf: return "생활"
        }
    }
}
