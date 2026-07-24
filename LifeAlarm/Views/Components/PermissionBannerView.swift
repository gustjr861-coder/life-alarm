import SwiftUI

/// 알림 권한 거부 시 설정 이동 배너
struct PermissionBannerView: View {
    @ObservedObject var notificationManager = NotificationManager.shared

    var body: some View {
        if notificationManager.authorizationStatus == .denied {
            VStack(alignment: .leading, spacing: 10) {
                Label("알림이 꺼져 있습니다", systemImage: "bell.slash.fill")
                    .font(.headline)
                Text("잠금화면·배너·알림센터에 표시하려면 설정에서 알림을 허용해 주세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    notificationManager.openSystemSettings()
                } label: {
                    Text("설정으로 이동")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.orange.opacity(0.12))
            )
        }
    }
}
