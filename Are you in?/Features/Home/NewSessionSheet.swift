import SwiftUI

struct NewSessionSheet: View {
    let partnerName: String
    /// Returns whether the round was actually created - lets the sheet show its own
    /// full loading state and only close once we know which way it went, instead of
    /// dismissing on a timer and hoping the home screen underneath has caught up.
    var onStart: @MainActor (Int, KinkIntensity, Bool) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var itemCount: Double = 10
    @State private var selectedIntensity: KinkIntensity = .mild
    /// Off by default: "up to this hardness" reads more naturally than "only exactly
    /// this hardness" - like a spice-level cap, not a single fixed shelf.
    @State private var exactIntensity = false
    @State private var catalog: [Kink] = []
    @State private var isCreating = false

    private var availableCount: Int {
        // Before the catalog has loaded, don't collapse the slider to a 1...1 range -
        // assume a generous default until `loadCatalog()` resolves with the real count.
        guard !catalog.isEmpty else { return 90 }
        let count = catalog.filter {
            exactIntensity ? $0.intensity == selectedIntensity.rawValue : $0.intensity <= selectedIntensity.rawValue
        }.count
        return max(count, 1)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isCreating {
                    creatingView
                } else {
                    formView
                }
            }
            .screenBackground()
            .toolbar {
                if !isCreating {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Mégse") { dismiss() }
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
            }
        }
        .interactiveDismissDisabled(isCreating)
        .task { await loadCatalog() }
        .onChange(of: selectedIntensity) { _, _ in itemCount = min(itemCount, Double(availableCount)) }
        .onChange(of: exactIntensity) { _, _ in itemCount = min(itemCount, Double(availableCount)) }
    }

    private var creatingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView().tint(Theme.Color.accent)
            Text("Kör indítása...")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Color.accent)
                    Text("Új kör \(partnerName)-val/vel")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Válaszd ki, hány preferenciát nézzetek át ebben a körben. Mindketten véletlenszerű sorrendben, egymástól függetlenül fogjátok látni őket.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.lg)

                Card {
                    VStack(spacing: Theme.Spacing.md) {
                        Text("\(Int(itemCount))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.Color.accent)
                        Slider(value: $itemCount, in: 1...Double(availableCount), step: 1)
                            .tint(Theme.Color.accent)
                        Text("preferencia ebben a körben")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }

                intensitySection

                Spacer(minLength: Theme.Spacing.md)

                Button {
                    startTapped()
                } label: {
                    Text("Kör indítása")
                }
                .buttonStyle(.primary)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func startTapped() {
        isCreating = true
        Task { @MainActor in
            let didStart = await onStart(Int(itemCount), selectedIntensity, exactIntensity)
            if didStart {
                dismiss()
            } else {
                isCreating = false
            }
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("MENNYIRE LEGYEN KEMÉNY")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.textSecondary)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(KinkIntensity.allCases) { level in
                    intensityOption(level)
                }
            }

            Toggle(isOn: $exactIntensity) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Csak ez a szint")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(
                        exactIntensity
                            ? "Csak \(selectedIntensity.label.lowercased()) szintű preferenciák kerülnek bele."
                            : "Az enyhébb szintek is bekerülhetnek, nemcsak a \(selectedIntensity.label.lowercased()) szint."
                    )
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .tint(Theme.Color.accent)
            .padding(.top, Theme.Spacing.xs)
        }
    }

    private func intensityOption(_ level: KinkIntensity) -> some View {
        let isSelected = selectedIntensity == level
        return Button {
            selectedIntensity = level
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { slot in
                        Image(systemName: slot < level.filledFlameCount ? "flame.fill" : "flame")
                            .font(.system(size: 13))
                            .foregroundStyle(slot < level.filledFlameCount ? Theme.Color.accent : Theme.Color.textTertiary)
                    }
                }
                Text(level.label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(isSelected ? Theme.Color.textPrimary : Theme.Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(isSelected ? Theme.Color.accentSoft : Theme.Color.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .strokeBorder(isSelected ? Theme.Color.accent : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func loadCatalog() async {
        if let kinks = try? await APIClient.shared.kinks(), !kinks.isEmpty {
            catalog = kinks
            itemCount = min(itemCount, Double(availableCount))
        }
    }
}

#Preview {
    NewSessionSheet(partnerName: "Jordan", onStart: { _, _, _ in true })
}
