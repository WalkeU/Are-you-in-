import SwiftUI

struct WaitingForPartnerView: View {
    let partnerName: String

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Color.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: "hourglass")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.Color.accent)
            }
            VStack(spacing: Theme.Spacing.sm) {
                Text("Végeztél!")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Most \(partnerName) válaszaira várunk. Amint befejezi, megmutatjuk az egyezéseiteket.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            ProgressView().tint(Theme.Color.accent)
        }
        .padding(Theme.Spacing.xl)
    }
}

#Preview {
    WaitingForPartnerView(partnerName: "Jordan")
        .screenBackground()
}
