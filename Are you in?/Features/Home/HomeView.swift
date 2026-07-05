import SwiftUI

struct HomeView: View {
    let user: User
    let partner: PartnerSummary

    @Environment(AppState.self) private var appState
    @State private var viewModel: HomeViewModel
    @State private var showingNewSession = false
    @State private var showingLogoutConfirmation = false
    @Binding var path: [AppRoute]

    init(user: User, partner: PartnerSummary, path: Binding<[AppRoute]>) {
        self.user = user
        self.partner = partner
        _viewModel = State(initialValue: HomeViewModel())
        _path = path
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header

                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) { viewModel.errorMessage = nil }
                }

                if let invite = viewModel.incomingInvite {
                    incomingInviteCard(invite)
                } else if let summary = viewModel.mySessionSummary {
                    inProgressCard(summary)
                } else {
                    startCard
                }

                shortcutsRow
            }
            .padding(Theme.Spacing.lg)
        }
        .screenBackground()
        .refreshable { await viewModel.load() }
        .task {
            await viewModel.load()
            viewModel.startPolling()
            #if DEBUG
            await UITestHarness.runHome(viewModel: viewModel, path: $path, initiatorId: user.id, partnerId: partner.id)
            #endif
        }
        .onDisappear { viewModel.stopPolling() }
        .sheet(isPresented: $showingNewSession) {
            NewSessionSheet(partnerName: partner.name) { count, maxIntensity, exactIntensity in
                let session = await viewModel.startSession(
                    itemCount: count,
                    maxIntensity: maxIntensity,
                    exactIntensity: exactIntensity,
                    initiatorId: user.id,
                    partnerId: partner.id
                )
                return session != nil
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.mySessionSummary == nil && viewModel.incomingInvite == nil {
                FullScreenLoading()
            }
        }
        .onChange(of: viewModel.mySessionSummary) { oldValue, newValue in
            // Partner just joined a round I started - jump both of us in rather than
            // leaving me stuck tapping "Folytatás" on a stale waiting screen.
            if let newValue, newValue.status == .active, oldValue?.status == .pending,
               !path.contains(.game(sessionId: newValue.id)) {
                path.append(.game(sessionId: newValue.id))
            }
        }
        .confirmationDialog(
            "Biztosan kijelentkezel?",
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Kijelentkezés és fiók törlése", role: .destructive) {
                Task { await appState.logout() }
            }
            Button("Mégse", role: .cancel) {}
        } message: {
            Text("Nincs visszalépés: a kijelentkezés véglegesen törli a válaszaidat és a fiókodat, nem tudsz majd ugyanazzal a fiókkal visszajelentkezni. A partnered oldalán a közösen lejátszott körök és egyezések megmaradnak.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Szia, \(user.name)")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("Összekapcsolva: \(partner.name)")
                            .font(Theme.Typography.caption)
                    }
                    .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
                Menu {
                    Button("Kijelentkezés", role: .destructive) {
                        showingLogoutConfirmation = true
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.md)
    }

    private var startCard: some View {
        Card {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Color.accent)
                Text("Kezdjetek egy új kört")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Válasszatok ki néhány preferenciát, és nézzétek meg, miben egyeztek.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Új kör indítása") { showingNewSession = true }
                    .buttonStyle(.primary)
            }
        }
    }

    private func incomingInviteCard(_ invite: PendingSession) -> some View {
        Card {
            VStack(spacing: Theme.Spacing.md) {
                PillLabel(text: "MEGHÍVÁS", tinted: true)
                Text("\(invite.initiator.name) elindított egy kört")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("\(invite.itemCount) preferencia vár rád ebben a körben.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                HStack(spacing: Theme.Spacing.sm) {
                    Button("Elutasítom") { Task { await viewModel.declineInvite() } }
                        .buttonStyle(.secondary)
                    Button("Elfogadom") {
                        Task {
                            if let sessionId = await viewModel.acceptInvite() {
                                path.append(.game(sessionId: sessionId))
                            }
                        }
                    }
                    .buttonStyle(.primary)
                }
            }
        }
    }

    private func inProgressCard(_ summary: SessionSummary) -> some View {
        Card {
            VStack(spacing: Theme.Spacing.md) {
                PillLabel(text: summary.status == .pending ? "VÁRAKOZÁS" : "FOLYAMATBAN")
                if summary.status == .pending {
                    Text("Várjuk, hogy \(partner.name) elfogadja a kört")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .multilineTextAlignment(.center)
                    ProgressView().tint(Theme.Color.accent)
                } else {
                    Text("Egy kör folyamatban van")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Button("Folytatás") { path.append(.game(sessionId: summary.id)) }
                        .buttonStyle(.primary)
                }
            }
        }
    }

    private var shortcutsRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                path.append(.history)
            } label: {
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20))
                    Text("Előzmények")
                        .font(Theme.Typography.caption)
                }
                .foregroundStyle(Theme.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Theme.Color.surface)
                )
            }
        }
    }
}
