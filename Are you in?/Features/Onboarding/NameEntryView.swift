import SwiftUI

struct NameEntryView: View {
    @Environment(AppState.self) private var appState
    @State private var name: String = ""
    @State private var isSubmitting = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                Text("Are You In?")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Fedezzétek fel közösen, mire mondanátok igent.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Hogy szólítsunk?")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.textSecondary)

                TextField("A neved", text: $name)
                    .focused($isFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(Theme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .fill(Theme.Color.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .strokeBorder(isFocused ? Theme.Color.accent : Theme.Color.border, lineWidth: 1)
                    )
                    .submitLabel(.done)
                    .onSubmit(submit)
            }

            if let errorMessage = appState.errorMessage {
                ErrorBanner(message: errorMessage)
            }

            Spacer()

            Button {
                submit()
            } label: {
                if isSubmitting {
                    ProgressView().tint(Theme.Color.textPrimary)
                } else {
                    Text("Kezdjük")
                }
            }
            .buttonStyle(.primary)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
        }
        .padding(Theme.Spacing.lg)
        .screenBackground()
        .onAppear { isFocused = true }
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSubmitting else { return }
        isFocused = false
        isSubmitting = true
        Task {
            await appState.register(name: trimmed)
            isSubmitting = false
        }
    }
}

#Preview {
    NameEntryView()
        .environment(AppState())
}
