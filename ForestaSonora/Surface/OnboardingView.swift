import SwiftUI

struct OnboardingView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @State private var page = 0

    private let slides: [(title: LocalizedStringKey, text: LocalizedStringKey, symbol: String, hue: Color)] = [
        ("onboarding.1.title", "onboarding.1.text", "leaf.fill", Palette.aqua),
        ("onboarding.2.title", "onboarding.2.text", "slider.horizontal.3", Palette.gold),
        ("onboarding.3.title", "onboarding.3.text", "moon.stars.fill", Palette.coral)
    ]

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    switch page < slides.count - 1 {
                    case true:
                        Button("onboarding.skip") { onboardingDone = true }
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.textSecondary)
                            .padding(.trailing, 24)
                            .padding(.top, 16)
                    case false:
                        EmptyView()
                    }
                }
                .frame(height: 44)

                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                        slideView(slide.title, slide.text, slide.symbol, slide.hue)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    let isLast = page >= slides.count - 1
                    switch isLast {
                    case true:
                        withAnimation(.linear(duration: 0.25)) { onboardingDone = true }
                    case false:
                        withAnimation(.linear(duration: 0.25)) { page += 1 }
                    }
                } label: {
                    Text(page < slides.count - 1 ? "onboarding.next" : "onboarding.start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryPillStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func slideView(_ title: LocalizedStringKey, _ text: LocalizedStringKey, _ symbol: String, _ hue: Color) -> some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Palette.panelMid)
                    .frame(width: 200, height: 200)
                Image(systemName: symbol)
                    .font(.system(size: 86, weight: .heavy))
                    .foregroundStyle(hue)
            }

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.textLight)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
            }

            Spacer()
            Spacer()
        }
    }
}
