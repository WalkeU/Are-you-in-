import SwiftUI

struct GameView: View {
    let sessionId: String
    let partnerName: String
    @Binding var path: [AppRoute]

    @State private var viewModel: GameViewModel

    init(sessionId: String, partnerName: String, path: Binding<[AppRoute]>) {
        self.sessionId = sessionId
        self.partnerName = partnerName
        _viewModel = State(initialValue: GameViewModel(sessionId: sessionId))
        _path = path
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if viewModel.stage == .answering {
                progressBar
            }

            Spacer()

            switch viewModel.stage {
            case .loading:
                FullScreenLoading()
            case .answering:
                if let item = viewModel.currentItem {
                    QuestionCardView(item: item) { answer in
                        handle(answer: answer, for: item)
                    }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    .id(item.id)
                }
            case .waitingForPartner:
                WaitingForPartnerView(partnerName: partnerName)
            case .completed:
                completedView
            case .failed(let message):
                VStack(spacing: Theme.Spacing.md) {
                    ErrorBanner(message: message)
                    Button("Újra") { Task { await viewModel.load() } }
                        .buttonStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .screenBackground()
        .navigationTitle("Kör")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.25), value: viewModel.stage)
        .task {
            await viewModel.load()
            #if DEBUG
            await UITestHarness.runGame(viewModel: viewModel, path: $path)
            #endif
        }
        .onDisappear { viewModel.stopPolling() }
        .sheet(item: Bindable(viewModel).awaitingRoleFor) { item in
            RoleQuestionView(
                itemName: item.name,
                onSelect: { role in
                    Task { await viewModel.answer(true, role: role) }
                },
                onSkip: {
                    Task { await viewModel.answer(true, role: nil) }
                }
            )
            .padding(Theme.Spacing.lg)
            .screenBackground()
            .presentationDetents([.medium])
        }
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Color.surfaceElevated)
                    Capsule()
                        .fill(Theme.Color.accent)
                        .frame(width: proxy.size.width * viewModel.progress)
                }
            }
            .frame(height: 6)
            Text("\(viewModel.currentIndex)/\(viewModel.items.count)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private var completedView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle().fill(Theme.Color.accentSoft).frame(width: 96, height: 96)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.Color.accent)
            }
            Text("A kör véget ért!")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Color.textPrimary)
            Button("Egyezések megtekintése") {
                path.append(.results(sessionId: sessionId))
            }
            .buttonStyle(.primary)
        }
    }

    private func handle(answer: Bool, for item: SessionItem) {
        if answer, item.hasRoleVariant {
            viewModel.awaitingRoleFor = item
        } else {
            Task { await viewModel.answer(answer, role: nil) }
        }
    }
}
