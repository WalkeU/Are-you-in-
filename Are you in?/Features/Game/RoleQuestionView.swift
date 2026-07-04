import SwiftUI

struct RoleQuestionView: View {
    let itemName: String
    var onSelect: (ResponseRole) -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Text("Milyen szerepben?")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("\(itemName) - te inkább adnád, kapnád, vagy mindkettőre nyitott lennél?")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(ResponseRole.allCases) { role in
                    Button {
                        onSelect(role)
                    } label: {
                        HStack {
                            Image(systemName: role.icon)
                            Text(role.label)
                            Spacer()
                        }
                    }
                    .buttonStyle(.secondary)
                }
            }

            Button("Kihagyás", action: onSkip)
                .buttonStyle(.ghost)
        }
    }
}

#Preview {
    RoleQuestionView(itemName: "Praise kink", onSelect: { _ in }, onSkip: {})
        .padding()
        .screenBackground()
}
