import SwiftUI

/// 반복 방식 + 요일/날짜/시간 선택
struct RepeatPickerView: View {
    @Binding var rule: RepeatRule

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("반복", selection: $rule.kind) {
                ForEach(RepeatKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            switch rule.kind {
            case .daily:
                EmptyView()
            case .weekly:
                weekdaySelector
            case .monthly:
                Stepper(value: $rule.dayOfMonth, in: 1...31) {
                    Text("매달 \(rule.dayOfMonth)일")
                }
            case .yearly:
                HStack {
                    Picker("월", selection: $rule.monthOfYear) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)월").tag(month)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("일", selection: $rule.dayOfYear) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)일").tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            DatePicker(
                "시간",
                selection: timeBinding,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)

            Text(rule.summaryText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var weekdaySelector: some View {
        let days = [2, 3, 4, 5, 6, 7, 1] // 월~일
        return HStack(spacing: 8) {
            ForEach(days, id: \.self) { day in
                let selected = rule.weekdays.contains(day)
                Button {
                    toggleWeekday(day)
                } label: {
                    Text(RepeatRule.weekdayName(day))
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .background(
                            Circle().fill(selected ? Color.accentColor : Color(.tertiarySystemFill))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleWeekday(_ day: Int) {
        // Binding 갱신을 위해 배열을 교체 할당한다.
        var weekdays = rule.weekdays
        if let idx = weekdays.firstIndex(of: day) {
            if weekdays.count > 1 {
                weekdays.remove(at: idx)
            }
        } else {
            weekdays.append(day)
            weekdays.sort()
        }
        rule.weekdays = weekdays
    }

    private var timeBinding: Binding<Date> {
        Binding {
            var comps = DateComponents()
            comps.hour = rule.hour
            comps.minute = rule.minute
            return Calendar.current.date(from: comps) ?? Date()
        } set: { newValue in
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            rule.hour = comps.hour ?? 9
            rule.minute = comps.minute ?? 0
        }
    }
}
