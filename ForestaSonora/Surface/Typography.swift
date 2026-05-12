import SwiftUI

extension Font {
    static let fsTitle = Font.system(size: 28, weight: .black, design: .rounded)
    static let fsHeadline = Font.system(size: 22, weight: .heavy, design: .rounded)
    static let fsSection = Font.system(size: 17, weight: .bold, design: .rounded)
    static let fsBody = Font.system(size: 15, weight: .regular, design: .rounded)
    static let fsCaption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let fsTimerHero = Font.system(size: 64, weight: .black, design: .rounded).monospacedDigit()
    static let fsBigDigit = Font.system(size: 36, weight: .heavy, design: .rounded).monospacedDigit()
    static let fsChip = Font.system(size: 13, weight: .semibold, design: .rounded)
}

struct PrimaryPillStyle: ButtonStyle {
    var gradient: LinearGradient = Palette.buttonPlay

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.fsSection)
            .foregroundStyle(Palette.backgroundDeep)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Palette.turquoise.opacity(0.45), radius: 16, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.linear(duration: 0.15), value: configuration.isPressed)
    }
}
