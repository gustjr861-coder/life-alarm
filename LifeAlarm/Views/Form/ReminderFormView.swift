import SwiftUI

/// 알림 추가 / 수정 폼
struct ReminderFormView: View {
    enum Mode {
        case create
        case edit(Reminder)
    }

    let mode: Mode
    @ObservedObject var viewModel: ReminderViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var repeatRule: RepeatRule = .defaultMonthlyRent
    @State private var isEnabled: Bool = true
    @State private var themeColor: ReminderThemeColor = .blue
    @State private var icon: ReminderIcon = .bell
    @State private var showValidationAlert = false

    private var navigationTitle: String {
        switch mode {
        case .create: return "알림 추가"
        case .edit: return "알림 수정"
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("기본 정보") {
                TextField("제목 (예: 월세)", text: $title)
                    .textInputAutocapitalization(.never)

                TextField("내용 (예: 김현석 월세 내는 날입니다.)", text: $bodyText, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.never)

                Toggle("알림 ON", isOn: $isEnabled)
            }

            Section("반복") {
                RepeatPickerView(rule: $repeatRule)
            }

            Section("색상") {
                ColorPickerRow(selection: $themeColor)
            }

            Section("아이콘") {
                IconPickerView(selection: $icon)
            }

            if case .edit(let reminder) = mode {
                Section("테스트") {
                    Button {
                        var draft = makeReminder(from: reminder.id, createdAt: reminder.createdAt, lastCompleted: reminder.lastCompletedDate)
                        draft.title = title.isEmpty ? reminder.title : title
                        draft.body = bodyText.isEmpty ? reminder.body : bodyText
                        viewModel.sendTestNotification(for: draft)
                    } label: {
                        Label("이 알림으로 테스트 보내기", systemImage: "paperplane.fill")
                    }
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    Text("저장")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .disabled(!canSave)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("닫기") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { save() }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
        .alert("입력 확인", isPresented: $showValidationAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("제목과 내용을 모두 입력해 주세요.")
        }
        .onAppear(perform: loadInitialValues)
    }

    private func loadInitialValues() {
        switch mode {
        case .create:
            title = ""
            bodyText = ""
            repeatRule = .defaultMonthlyRent
            isEnabled = true
            themeColor = .blue
            icon = .bell
        case .edit(let reminder):
            title = reminder.title
            bodyText = reminder.body
            repeatRule = reminder.repeatRule
            isEnabled = reminder.isEnabled
            themeColor = reminder.themeColor
            icon = reminder.icon
        }
    }

    private func save() {
        guard canSave else {
            showValidationAlert = true
            return
        }

        switch mode {
        case .create:
            let reminder = makeReminder(from: UUID(), createdAt: Date(), lastCompleted: nil)
            viewModel.add(reminder)
        case .edit(let existing):
            let reminder = makeReminder(
                from: existing.id,
                createdAt: existing.createdAt,
                lastCompleted: existing.lastCompletedDate
            )
            viewModel.update(reminder)
        }
        dismiss()
    }

    private func makeReminder(from id: UUID, createdAt: Date, lastCompleted: Date?) -> Reminder {
        Reminder(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
            repeatRule: repeatRule,
            isEnabled: isEnabled,
            themeColor: themeColor,
            icon: icon,
            createdAt: createdAt,
            lastCompletedDate: lastCompleted
        )
    }
}
