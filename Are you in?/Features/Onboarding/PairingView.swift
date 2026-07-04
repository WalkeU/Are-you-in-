import SwiftUI

struct PairingView: View {
    let user: User

    @Environment(AppState.self) private var appState
    @State private var partnerCode: String = ""
    @State private var isSubmitting = false
    @State private var pollTask: Task<Void, Never>?
    @State private var showingLogoutConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Szia, \(user.name)!")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Kapcsolódj össze a partnereddel a folytatáshoz.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                Card {
                    VStack(spacing: Theme.Spacing.md) {
                        Text("A TE MEGHÍVÓKÓDOD")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Color.textSecondary)

                        Text(user.inviteCode)
                            .font(Theme.Typography.mono)
                            .tracking(4)
                            .foregroundStyle(Theme.Color.accent)
                            .padding(.vertical, Theme.Spacing.sm)

                        ShareLink(item: "Csatlakozz hozzám az Are You In?-ban a(z) \(user.inviteCode) kóddal!") {
                            Label("Kód megosztása", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.secondary)
                    }
                }

                HStack {
                    Rectangle().fill(Theme.Color.border).frame(height: 1)
                    Text("VAGY")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.textTertiary)
                    Rectangle().fill(Theme.Color.border).frame(height: 1)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Add meg a partnered kódját")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.textSecondary)

                    TextField("PL. 7K3M9QX", text: $partnerCode)
                        .textInputAutocapitalization(.characters)
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
                                .strokeBorder(Theme.Color.border, lineWidth: 1)
                        )

                    if let errorMessage = appState.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView().tint(Theme.Color.textPrimary)
                        } else {
                            Text("Összekapcsolás")
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(partnerCode.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }

                Button("Kijelentkezés") {
                    showingLogoutConfirmation = true
                }
                .buttonStyle(.ghost)
                .padding(.top, Theme.Spacing.md)
            }
            .padding(Theme.Spacing.lg)
        }
        .screenBackground()
        .refreshable { await appState.refreshProfile() }
        .task { await pollForPartner() }
        .onDisappear { pollTask?.cancel() }
        .confirmationDialog(
            "Biztosan kijelentkezel?",
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Kijelentkezés", role: .destructive) {
                Task { await appState.logout() }
            }
            Button("Mégse", role: .cancel) {}
        }
    }

    private func submit() {
        let code = partnerCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty, !isSubmitting else { return }
        isSubmitting = true
        Task {
            _ = await appState.pair(inviteCode: code)
            isSubmitting = false
        }
    }

    /// The partner might pair from their side while I'm sitting on this screen, so poll
    /// in the background rather than requiring a manual pull-to-refresh to notice it.
    private func pollForPartner() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(4))
            if Task.isCancelled { return }
            await appState.refreshProfile()
        }
    }
}

#Preview {
    PairingView(user: User(id: "1", name: "Alex", inviteCode: "7K3M9QX", partnerId: nil, createdAt: .now))
        .environment(AppState())
}
