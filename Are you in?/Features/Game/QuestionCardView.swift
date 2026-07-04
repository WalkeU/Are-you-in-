import SwiftUI

struct QuestionCardView: View {
    let item: SessionItem
    var onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                Text(item.name)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text(item.description)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 220)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .fill(Theme.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .strokeBorder(Theme.Color.border, lineWidth: 1)
            )

            HStack(spacing: Theme.Spacing.lg) {
                answerButton(symbol: "xmark", tint: Theme.Color.textSecondary) { onAnswer(false) }
                answerButton(symbol: "checkmark", tint: Theme.Color.accent) { onAnswer(true) }
            }
        }
    }

    private func answerButton(symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 76, height: 76)
                .background(Circle().fill(Theme.Color.surfaceElevated))
                .overlay(Circle().strokeBorder(tint.opacity(0.5), lineWidth: 1.5))
        }
    }
}

#Preview {
    QuestionCardView(
        item: SessionItem(kinkId: "1", name: "Praise kink", description: "A dicséret és elismerés különösen izgató.", hasRoleVariant: true, myAnswer: nil, myRole: nil),
        onAnswer: { _ in }
    )
    .padding()
    .screenBackground()
}
