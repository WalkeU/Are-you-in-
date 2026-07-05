import SwiftUI

struct RoleQuestionView: View {
    let itemName: String
    let roleALabel: String
    let roleBLabel: String
    var onSelect: (ResponseRole) -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Text("Milyen szerepben?")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("\(itemName) — melyik szerep illik hozzád?")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    onSelect(.roleA)
                } label: {
                    HStack {
                        Image(systemName: ResponseRole.roleA.icon)
                        Text(roleALabel)
                        Spacer()
                    }
                }
                .buttonStyle(.secondary)

                Button {
                    onSelect(.roleB)
                } label: {
                    HStack {
                        Image(systemName: ResponseRole.roleB.icon)
                        Text(roleBLabel)
                        Spacer()
                    }
                }
                .buttonStyle(.secondary)

                Button {
                    onSelect(.both)
                } label: {
                    HStack {
                        Image(systemName: ResponseRole.both.icon)
                        Text("Mindkettő")
                        Spacer()
                    }
                }
                .buttonStyle(.secondary)
            }

            Button("Kihagyás", action: onSkip)
                .buttonStyle(.ghost)
        }
    }
}

#Preview {
    RoleQuestionView(
        itemName: "Praise kink",
        roleALabel: "Domináns",
        roleBLabel: "Szubmisszív",
        onSelect: { _ in },
        onSkip: {}
    )
    .padding()
    .screenBackground()
}
