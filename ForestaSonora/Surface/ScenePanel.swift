import SwiftUI

enum SceneMood {
    case river, night, dawn, waterfall, focus, generic

    var skyPalette: [Color] {
        switch self {
        case .river:     return [Color(hex: 0x6FFACC), Color(hex: 0x0097C2), Color(hex: 0x002F40)]
        case .night:     return [Color(hex: 0x162447), Color(hex: 0x1E3C72), Color(hex: 0x051D22)]
        case .dawn:      return [Color(hex: 0xFFB347), Color(hex: 0xFF7A6E), Color(hex: 0x83235D)]
        case .waterfall: return [Color(hex: 0xCFF7FF), Color(hex: 0x6FFACC), Color(hex: 0x0F4C75)]
        case .focus:     return [Color(hex: 0x9CFF8C), Color(hex: 0x0F4C5C), Color(hex: 0x051D22)]
        case .generic:   return [Color(hex: 0x0F253D), Color(hex: 0x0F1628)]
        }
    }
}

struct ScenePanel: View {
    let title: LocalizedStringKey
    let mood: SceneMood
    let assetName: String?
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            backdrop
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                    location: 0.0),
                            .init(color: Color.black.opacity(0.0),  location: 0.40),
                            .init(color: Color.black.opacity(0.55), location: 0.80),
                            .init(color: Color.black.opacity(0.82), location: 1.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.8), radius: 4, y: 1)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 9, weight: .black))
                            Text("Avvia")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(Palette.backgroundDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(accent))
                    }
                    .padding(12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accent.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backdrop: some View {
        if let assetName, UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(colors: mood.skyPalette,
                               startPoint: .top, endPoint: .bottom)
                CartoonScenePainting(mood: mood)
            }
        }
    }
}

struct CartoonScenePainting: View {
    let mood: SceneMood

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch mood {
                case .river:     riverComposition(in: geo.size)
                case .night:     nightComposition(in: geo.size)
                case .dawn:      dawnComposition(in: geo.size)
                case .waterfall: waterfallComposition(in: geo.size)
                case .focus:     focusComposition(in: geo.size)
                case .generic:   genericComposition(in: geo.size)
                }
            }
        }
    }

    private func riverComposition(in size: CGSize) -> some View {
        ZStack {
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.55, weight: .black))
                .foregroundStyle(Color(hex: 0x1BB90D).opacity(0.55))
                .rotationEffect(.degrees(-25))
                .offset(x: -size.width * 0.32, y: -size.height * 0.20)
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.4, weight: .black))
                .foregroundStyle(Color(hex: 0x9CFF8C).opacity(0.4))
                .rotationEffect(.degrees(150))
                .offset(x: size.width * 0.30, y: -size.height * 0.30)
            Image(systemName: "bird.fill")
                .font(.system(size: size.height * 0.18, weight: .heavy))
                .foregroundStyle(Color(hex: 0xFAA61A))
                .offset(x: size.width * 0.20, y: -size.height * 0.05)
            Wave()
                .fill(Color(hex: 0x6FFACC).opacity(0.55))
                .frame(height: size.height * 0.32)
                .offset(y: size.height * 0.28)
            Wave(phase: 0.5)
                .fill(Color(hex: 0xCFF7FF).opacity(0.45))
                .frame(height: size.height * 0.22)
                .offset(y: size.height * 0.36)
        }
    }

    private func nightComposition(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFEC502))
                .frame(width: size.height * 0.32, height: size.height * 0.32)
                .offset(x: size.width * 0.25, y: -size.height * 0.30)
                .shadow(color: Color(hex: 0xFEC502).opacity(0.5), radius: 12)
            ForEach(0..<8, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .offset(
                        x: CGFloat.random(in: -size.width/2.2...size.width/2.2),
                        y: CGFloat.random(in: -size.height/2.2 ... -size.height*0.05)
                    )
                    .id(i)
            }
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.45, weight: .black))
                .foregroundStyle(Color(hex: 0x144A3C).opacity(0.85))
                .rotationEffect(.degrees(-15))
                .offset(x: -size.width * 0.30, y: -size.height * 0.18)
            MountainSilhouette()
                .fill(Color(hex: 0x051D22))
                .frame(height: size.height * 0.42)
                .offset(y: size.height * 0.22)
        }
    }

    private func dawnComposition(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: 0xFEC502), Color(hex: 0xFF7A6E)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size.height * 0.45, height: size.height * 0.45)
                .offset(y: size.height * 0.06)
                .blur(radius: 4)
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.5, weight: .black))
                .foregroundStyle(Color(hex: 0x051D22).opacity(0.7))
                .rotationEffect(.degrees(-30))
                .offset(x: -size.width * 0.35, y: -size.height * 0.05)
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.4, weight: .black))
                .foregroundStyle(Color(hex: 0x051D22).opacity(0.55))
                .rotationEffect(.degrees(140))
                .offset(x: size.width * 0.32, y: -size.height * 0.08)
            Image(systemName: "bird")
                .font(.system(size: size.height * 0.12, weight: .heavy))
                .foregroundStyle(Color(hex: 0x051D22).opacity(0.85))
                .offset(x: size.width * 0.06, y: -size.height * 0.20)
        }
    }

    private func waterfallComposition(in size: CGSize) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 4, height: size.height * 0.6)
                    .offset(x: CGFloat(i - 2) * size.width * 0.07, y: size.height * 0.05)
                    .blur(radius: 2)
            }
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.42, weight: .black))
                .foregroundStyle(Color(hex: 0x144A3C).opacity(0.7))
                .rotationEffect(.degrees(-22))
                .offset(x: -size.width * 0.34, y: -size.height * 0.18)
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.36, weight: .black))
                .foregroundStyle(Color(hex: 0x1BB90D).opacity(0.5))
                .rotationEffect(.degrees(155))
                .offset(x: size.width * 0.34, y: -size.height * 0.20)
            Wave(phase: 0.2)
                .fill(Color(hex: 0x6FFACC).opacity(0.6))
                .frame(height: size.height * 0.30)
                .offset(y: size.height * 0.32)
        }
    }

    private func focusComposition(in size: CGSize) -> some View {
        ZStack {
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.6, weight: .black))
                .foregroundStyle(Color(hex: 0x1BB90D).opacity(0.6))
                .rotationEffect(.degrees(-15))
                .offset(x: -size.width * 0.05, y: -size.height * 0.05)
            Image(systemName: "leaf")
                .font(.system(size: size.height * 0.35, weight: .heavy))
                .foregroundStyle(Color(hex: 0x9CFF8C).opacity(0.7))
                .rotationEffect(.degrees(40))
                .offset(x: size.width * 0.30, y: size.height * 0.20)
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color(hex: 0x9CFF8C).opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat([-0.30, 0.10, 0.32, -0.15, 0.20, -0.40][i]) * size.width,
                        y: CGFloat([-0.25, -0.10, 0.05, 0.15, -0.30, 0.10][i]) * size.height
                    )
            }
        }
    }

    private func genericComposition(in size: CGSize) -> some View {
        ZStack {
            Image(systemName: "leaf.fill")
                .font(.system(size: size.height * 0.5, weight: .black))
                .foregroundStyle(Color.white.opacity(0.12))
                .rotationEffect(.degrees(-15))
                .offset(x: size.width * 0.20, y: -size.height * 0.15)
        }
    }
}

private struct Wave: Shape {
    var phase: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let amp = rect.height * 0.45
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: midY))
        for x in stride(from: 0, through: rect.width, by: 4) {
            let relativeX = x / rect.width
            let sine = sin((relativeX + phase) * .pi * 2)
            let y = midY + sine * amp
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MountainSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.width * 0.20, y: rect.height * 0.20))
        path.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.width * 0.58, y: rect.height * 0.10))
        path.addLine(to: CGPoint(x: rect.width * 0.80, y: rect.height * 0.50))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct FeaturedScenePanel: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let assetName: String?
    let palette: [Color]
    let onTap: () -> Void

    @ViewBuilder
    private var backdrop: some View {
        if let assetName, UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(colors: palette,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        Button(action: onTap) {
            backdrop
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .overlay(
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.05), location: 0.0),
                            .init(color: Color.black.opacity(0.0),  location: 0.35),
                            .init(color: Color.black.opacity(0.55), location: 0.75),
                            .init(color: Color.black.opacity(0.85), location: 1.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 6) {
                        Circle().fill(Palette.aqua).frame(width: 7, height: 7)
                            .shadow(color: Palette.aqua, radius: 4)
                        Text("In primo piano")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white.opacity(0.95))
                            .textCase(.uppercase)
                            .tracking(1.2)
                    }
                    .padding(20)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 6, y: 2)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.7), radius: 4, y: 1)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .black))
                            Text("Avvia il paesaggio")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                        }
                        .foregroundStyle(Palette.backgroundDeep)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Palette.aqua))
                        .shadow(color: Palette.aqua.opacity(0.5), radius: 12, y: 4)
                        .padding(.top, 4)
                    }
                    .padding(20)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Palette.aqua.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
