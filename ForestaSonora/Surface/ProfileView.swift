import SwiftUI

struct ProfileView: View {
    @Environment(\.soundscape) private var journal
    @EnvironmentObject private var engine: AudioEngine
    @State private var defaultDuration: Int = 30
    @State private var defaultVolume: Float = 0.8
    @State private var fade: Bool = true
    @State private var showPrivacy: Bool = false

    private let durationOptions = [15, 30, 45, 60, 90]

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerPanel
                    settingsSection
                    linksSection
                    versionLabel
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
            }
        }
        .navigationTitle("profile.title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await engine.refresh()
            defaultDuration = engine.snapshot.defaultDuration
            defaultVolume = engine.snapshot.masterVolume
            fade = engine.snapshot.isFading
        }
    }

    private var headerPanel: some View {
        HStack(spacing: 14) {
            ZStack {
                if UIImage(named: "scenePioggia") != nil {
                    Image("scenePioggia")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    LinearGradient(colors: [Palette.aqua, Palette.azure],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Palette.aqua.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 70, height: 70)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Palette.gold)
                    .shadow(color: .black.opacity(0.5), radius: 6)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.textLight)
                Text("home.tagline")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Palette.panelMid.opacity(0.7))
        )
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.settings")
                .font(.fsSection)
                .foregroundStyle(Palette.textLight)

            VStack(spacing: 14) {
                durationRow
                volumeRow
                fadeRow
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Palette.panelMid.opacity(0.7))
            )
        }
    }

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("profile.default_duration")
                .font(.fsCaption)
                .foregroundStyle(Palette.textSecondary)
            HStack(spacing: 8) {
                ForEach(durationOptions, id: \.self) { value in
                    let active = defaultDuration == value
                    Button {
                        defaultDuration = value
                        Task { await journal.setDefaultDuration(value); await engine.refresh() }
                    } label: {
                        Text("\(value) min")
                            .font(.fsChip)
                            .foregroundStyle(active ? Palette.backgroundDeep : Palette.textLight)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(active ? Palette.turquoise : Palette.backgroundDeep.opacity(0.65)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var volumeRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("profile.default_volume")
                .font(.fsCaption)
                .foregroundStyle(Palette.textSecondary)
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill").foregroundStyle(Palette.textSecondary)
                Slider(value: Binding(
                    get: { Double(defaultVolume) },
                    set: { value in
                        defaultVolume = Float(value)
                        Task { await engine.setMaster(Float(value)) }
                    }
                ), in: 0...1)
                .tint(Palette.gold)
                Image(systemName: "speaker.wave.3.fill").foregroundStyle(Palette.gold)
            }
        }
    }

    private var fadeRow: some View {
        Toggle(isOn: Binding(
            get: { fade },
            set: { value in
                fade = value
                Task { await journal.setFading(value); await engine.refresh() }
            }
        )) {
            Text("timer.fade_label")
                .font(.fsCaption)
                .foregroundStyle(Palette.textLight)
        }
        .tint(Palette.turquoise)
    }

    private var linksSection: some View {
        VStack(spacing: 10) {
            NavigationLink(destination: SoundCreditsView()) {
                linkRow(symbol: "music.note.list", title: "profile.credits", color: Palette.aqua)
            }
            .buttonStyle(.plain)

            Button {
                openSupport()
            } label: {
                linkRow(symbol: "envelope.fill", title: "profile.support", color: Palette.gold)
            }
            .buttonStyle(.plain)

            Button {
                showPrivacy = true
            } label: {
                linkRow(symbol: "hand.raised.fill", title: "profile.privacy", color: Palette.coral)
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }

    private func linkRow(symbol: String, title: LocalizedStringKey, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.2)).frame(width: 38, height: 38)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.fsBody)
                .foregroundStyle(Palette.textLight)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.panelMid.opacity(0.7))
        )
    }

    private var versionLabel: some View {
        HStack {
            Spacer()
            Text("\(String(localized: "profile.version")) \(versionString)")
                .font(.fsCaption)
                .foregroundStyle(Palette.textSecondary)
            Spacer()
        }
        .padding(.top, 12)
    }

    private var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ""
    }

    private var versionString: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    private func openSupport() {
        let mailto = "mailto:\(AppConfig.supportEmail)?subject=Foresta%20Sonora%20Support"
        if let url = URL(string: mailto) {
            UIApplication.shared.open(url)
        }
    }
}
