import SwiftUI

struct NewSessionSheet: View {
    let partnerName: String
    var onStart: (Int) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var itemCount: Double = 10
    @State private var maxItems: Double = 90
    @State private var isStarting = false

    var body: some View {
        NavigationStack {
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
                        Slider(value: $itemCount, in: 1...max(maxItems, 1), step: 1)
                            .tint(Theme.Color.accent)
                        Text("preferencia ebben a körben")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }

                Spacer()

                Button {
                    isStarting = true
                    Task {
                        await onStart(Int(itemCount))
                        isStarting = false
                        dismiss()
                    }
                } label: {
                    if isStarting {
                        ProgressView().tint(Theme.Color.textPrimary)
                    } else {
                        Text("Kör indítása")
                    }
                }
                .buttonStyle(.primary)
                .disabled(isStarting)
            }
            .padding(Theme.Spacing.lg)
            .screenBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Mégse") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .task { await loadCatalogSize() }
    }

    private func loadCatalogSize() async {
        if let kinks = try? await APIClient.shared.kinks(), !kinks.isEmpty {
            maxItems = Double(kinks.count)
            itemCount = min(itemCount, maxItems)
        }
    }
}

#Preview {
    NewSessionSheet(partnerName: "Jordan", onStart: { _ in })
}
