import SwiftUI

/// One-time 18+ / informed-consent gate shown before anything else in the app
/// (even before name entry), so nobody reaches explicit content without acknowledging
/// it first. Persisted in `UserDefaults` via `@AppStorage` - shown again only if the
/// app is reinstalled/deleted, never on every launch.
struct AdultContentGateView: View {
    @AppStorage("hasAcceptedAdultContentWarning") private var hasAccepted = false

    @State private var confirmedAge = false
    @State private var confirmedSafety = false
    @State private var showDeclineAlert = false

    private var canContinue: Bool { confirmedAge && confirmedSafety }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.Color.accent)
                    Text("18+ tartalom")
                        .font(Theme.Typography.largeTitle)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Mielőtt folytatnád, olvasd el figyelmesen.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                Card {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        infoRow(
                            icon: "person.fill.checkmark",
                            text: "Az alkalmazás kizárólag 18 éven felüli, egymással kölcsönösen beleegyező felnőttek számára készült."
                        )
                        infoRow(
                            icon: "text.bubble.fill",
                            text: "Szexuálisan explicit témák, kifejezések és preferenciák (BDSM, fetisek, szerepjátékok stb.) jelennek meg benne."
                        )
                        infoRow(
                            icon: "heart.fill",
                            text: "Csak saját felelősségre használjátok. Ha bármi kellemetlen érzést kelt, álljatok le, és beszéljetek róla egymással őszintén."
                        )
                        infoRow(
                            icon: "shield.lefthalf.filled",
                            text: "Ez nem helyettesíti a szakszerű tanácsadást vagy terápiát. Mindig tartsátok be a kölcsönös beleegyezés és a biztonság alapelveit."
                        )
                        infoRow(
                            icon: "xmark.octagon.fill",
                            text: "A tartalom kizárólag konszenzuális felnőtt fantáziákra vonatkozik - semmilyen illegális vagy beleegyezés nélküli tevékenységet nem támogat."
                        )
                    }
                }

                VStack(spacing: Theme.Spacing.md) {
                    consentToggle(
                        isOn: $confirmedAge,
                        text: "Elmúltam 18 éves vagyok."
                    )
                    consentToggle(
                        isOn: $confirmedSafety,
                        text: "Elolvastam a fentieket, elfogadom őket, és vigyázok magamra és a partneremre."
                    )
                }

                VStack(spacing: Theme.Spacing.sm) {
                    Button("Elfogadom és belépek") {
                        hasAccepted = true
                    }
                    .buttonStyle(.primary)
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.5)

                    Button("Nem fogadom el") {
                        showDeclineAlert = true
                    }
                    .buttonStyle(.ghost)
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(Theme.Spacing.lg)
        }
        .screenBackground()
        .alert("Nem lehet folytatni", isPresented: $showDeclineAlert) {
            Button("Rendben", role: .cancel) {}
        } message: {
            Text("Az alkalmazás használatához el kell fogadnod a fenti feltételeket. Zárd be az appot, ha nem szeretnéd elfogadni őket.")
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Color.accent)
                .frame(width: 20)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func consentToggle(isOn: Binding<Bool>, text: String) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn.wrappedValue ? Theme.Color.accent : Theme.Color.textTertiary)
                Text(text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AdultContentGateView()
}
