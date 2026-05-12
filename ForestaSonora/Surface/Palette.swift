import SwiftUI

// note: палитра подогнана под Amazon Slots brand-coolDark.css
// note: backgroundDeep #0f1628, panelMid #0f253d, panelHigh #002f40 — родные bg
// note: azure #3385ff, aqua #6ffacc — родные CTA + highlight
// note: gold #fec502 — родной jackpot. Coral/pink/lime — warm-mood контрасты
struct Palette {
    static let turquoise   = Color(hex: 0x0097C2)
    static let aqua        = Color(hex: 0x6FFACC)
    static let azure       = Color(hex: 0x3385FF)
    static let neonMint    = Color(hex: 0x13FFEB)
    static let backgroundDeep = Color(hex: 0x0F1628)
    static let panelMid    = Color(hex: 0x0F253D)
    static let panelHigh   = Color(hex: 0x002F40)
    static let gold        = Color(hex: 0xFEC502)
    static let amber       = Color(hex: 0xFAA61A)
    static let coral       = Color(hex: 0xFF7A6E)
    static let pink        = Color(hex: 0xFF9CC8)
    static let lime        = Color(hex: 0x9CFF8C)
    static let jungleDeep  = Color(hex: 0x051D22)
    static let success     = Color(hex: 0x1BB90D)
    static let danger      = Color(hex: 0xB90D10)
    static let textLight   = Color(hex: 0xE8F1F5)
    static let textSecondary = Color(hex: 0x8FB6C0)
    static let inactive    = Color(hex: 0x3A6478)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x0F1628), Color(hex: 0x0F253D), Color(hex: 0x002F40)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let buttonPlay = LinearGradient(
        colors: [Palette.aqua, Palette.azure],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let buttonAccent = LinearGradient(
        colors: [Palette.gold, Palette.amber],
        startPoint: .leading, endPoint: .trailing
    )
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >> 8) / 255.0
        let b = Double(hex & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
