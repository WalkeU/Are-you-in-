import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @State private var selectedTab: Tab = .matches

    enum Tab: String, CaseIterable {
        case matches = "Közös egyezések"
        case mine = "Saját válaszaim"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Picker("Nézet", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)

            if viewModel.isLoading {
                FullScreenLoading()
            } else {
                switch selectedTab {
                case .matches:
                    matchesList
                case .mine:
                    myResponsesList
                }
            }
        }
        .screenBackground()
        .navigationTitle("Előzmények")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var matchesList: some View {
        Group {
            if viewModel.matches.isEmpty {
                emptyState(text: "Még nincs közös egyezésetek. Játsszatok egy kört, hogy felfedezzétek!")
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.matches) { entry in
                            Card {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    HStack {
                                        Text(entry.name)
                                            .font(Theme.Typography.headline)
                                            .foregroundStyle(Theme.Color.textPrimary)
                                        Spacer()
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(Theme.Color.accent)
                                    }
                                    Text(entry.description)
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.Color.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
    }

    private var myResponsesList: some View {
        Group {
            if viewModel.myResponses.isEmpty {
                emptyState(text: "Még nincs korábbi válaszod egyetlen befejezett körből sem.")
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(viewModel.myResponses) { entry in
                            Card {
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    HStack {
                                        Text(entry.name)
                                            .font(Theme.Typography.headline)
                                            .foregroundStyle(Theme.Color.textPrimary)
                                        Spacer()
                                        Image(systemName: entry.answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(entry.answer ? Theme.Color.success : Theme.Color.textTertiary)
                                    }
                                    if let role = entry.role {
                                        PillLabel(text: role.label)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
    }

    private func emptyState(text: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(Theme.Color.textTertiary)
            Text(text)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xl)
    }
}
