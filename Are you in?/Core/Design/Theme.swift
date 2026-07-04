import SwiftUI

/// Monochrome-first, near-black design language with a single red accent reserved for
/// primary actions, matches, and emphasis - kept out of decorative use so it stays
/// meaningful when it appears.
enum Theme {
    enum Color {
        static let background = SwiftUI.Color(hex: 0x0A0A0B)
        static let surface = SwiftUI.Color(hex: 0x151517)
        static let surfaceElevated = SwiftUI.Color(hex: 0x1F1F22)
        static let border = SwiftUI.Color(hex: 0x2C2C30)

        static let textPrimary = SwiftUI.Color(hex: 0xF5F5F6)
        static let textSecondary = SwiftUI.Color(hex: 0x9A9AA0)
        static let textTertiary = SwiftUI.Color(hex: 0x616166)

        static let accent = SwiftUI.Color(hex: 0xE8324A)
        static let accentDim = SwiftUI.Color(hex: 0x7A1B27)
        static let accentSoft = SwiftUI.Color(hex: 0xE8324A).opacity(0.14)

        static let success = SwiftUI.Color(hex: 0x3DBE7A)
        static let danger = accent
    }

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 18, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 13, weight: .medium)
        static let mono = Font.system(size: 20, weight: .bold, design: .monospaced)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let pill: CGFloat = 999
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
