import SwiftUI

struct ResultsView: View {
    let sessionId: String
    let partnerName: String
    @Binding var path: [AppRoute]

    @State private var viewModel: ResultsViewModel

    init(sessionId: String, partnerName: String, path: Binding<[AppRoute]>) {
        self.sessionId = sessionId
        self.partnerName = partnerName
        _path = path
        _viewModel = State(initialValue: ResultsViewModel(sessionId: sessionId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                FullScreenLoading()
            } else if viewModel.matches.isEmpty {
                emptyState
            } else {
                matchList
            }
        }
        .screenBackground()
        .navigationTitle("Egyezések")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Kész") { path.removeAll() }
            }
        }
        .task { await viewModel.load() }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Color.textTertiary)
            Text("Ebben a körben nem volt közös egyezés")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("Ez teljesen rendben van - próbáljatok ki egy új kört más preferenciákkal.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }

    private var matchList: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("\(viewModel.matches.count) közös egyezés")
                        .font(Theme.Typography.largeTitle)
                        .foregroundStyle(Theme.Color.accent)
                    Text("Mindketten igent mondtatok ezekre")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.sm)

                ForEach(viewModel.matches) { match in
                    MatchCard(match: match, partnerName: partnerName)
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
}

struct MatchCard: View {
    let match: MatchResult
    let partnerName: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text(match.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Color.accent)
                }
                Text(match.description)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.textSecondary)

                if match.myRole != nil || match.partnerRole != nil {
                    HStack(spacing: Theme.Spacing.xs) {
                        if let myRole = match.myRole, myRole == match.partnerRole {
                            PillLabel(text: "Mindketten: \(myRole.label)", tinted: true)
                        } else {
                            if let myRole = match.myRole {
                                PillLabel(text: "Te: \(myRole.label)", tinted: true)
                            }
                            if let partnerRole = match.partnerRole {
                                PillLabel(text: "\(partnerName): \(partnerRole.label)", tinted: true)
                            }
                        }
                    }
                }
            }
        }
    }
}
