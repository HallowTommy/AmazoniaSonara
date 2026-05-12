import SwiftUI

struct HomeView: View {
    @Environment(\.soundscape) private var journal
    @EnvironmentObject private var engine: AudioEngine
    @AppStorage("startTab") private var startTabRaw: String = "home"

    private let modes: [(id: String, title: LocalizedStringKey, symbol: String, hue: Color)] = [
        ("sonno",       "mode.sonno",       "moon.fill",                   Palette.azure),
        ("relax",       "mode.relax",       "leaf.fill",                   Palette.aqua),
        ("focus",       "mode.focus",       "circle.hexagongrid.fill",     Palette.lime),
        ("meditazione", "mode.meditazione", "sparkles",                    Palette.pink)
    ]

    private let quickActions: [(symbol: String, title: LocalizedStringKey, tab: RootTab, tint: Color)] = [
        ("slider.horizontal.3",   "tab.mixer",   .mixer,   Palette.aqua),
        ("moon.zzz.fill",         "tab.timer",   .timer,   Palette.azure),
        ("square.stack.fill",     "tab.presets", .presets, Palette.gold),
        ("music.note.list",       "profile.credits", .profile, Palette.coral)
    ]

    private struct SceneEntry {
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
        let asset: String?
        let mood: SceneMood
        let accent: Color
        let mix: SoundMix
    }

    private var featured: SceneEntry {
        SceneEntry(
            title: "scene.pioggia_amazzonica",
            subtitle: "Pioggia tropicale, cicale e tuoni in lontananza",
            asset: "scenePioggia",
            mood: .generic,
            accent: Palette.aqua,
            mix: SoundMix(name: "Pioggia Amazzonica", levels: [.pioggia: 0.85, .cicale: 0.35, .tuono: 0.25])
        )
    }

    private var scenes: [SceneEntry] {
        [
            SceneEntry(title: "scene.fiume_turchese", subtitle: "L'acqua scorre tra le pietre",
                       asset: "sceneFiume", mood: .river, accent: Palette.gold,
                       mix: SoundMix(name: "Fiume Turchese", levels: [.fiume: 0.80, .uccelli: 0.40])),
            SceneEntry(title: "scene.notte_foresta", subtitle: "Cicale e foglie sotto la luna",
                       asset: "sceneNotte", mood: .night, accent: Palette.gold,
                       mix: SoundMix(name: "Notte nella Foresta", levels: [.cicale: 0.75, .foglie: 0.45, .vento: 0.35])),
            SceneEntry(title: "scene.alba_foresta", subtitle: "Uccelli all'alba",
                       asset: "sceneAlba", mood: .dawn, accent: Palette.gold,
                       mix: SoundMix(name: "Alba nella Foresta", levels: [.uccelli: 0.85, .foglie: 0.40, .vento: 0.25])),
            SceneEntry(title: "scene.cascata_serena", subtitle: "Una cascata costante",
                       asset: "sceneCascata", mood: .waterfall, accent: Palette.gold,
                       mix: SoundMix(name: "Cascata Serena", levels: [.cascata: 0.90, .uccelli: 0.30])),
            SceneEntry(title: "scene.focus_tropicale", subtitle: "Foglie e pioggia per concentrarsi",
                       asset: "sceneFocus", mood: .focus, accent: Palette.lime,
                       mix: SoundMix(name: "Focus Tropicale", levels: [.pioggia: 0.45, .foglie: 0.55]))
        ]
    }

    @State private var modeId: String = "sonno"

    var body: some View {
        ZStack {
            Palette.heroGradient.ignoresSafeArea()
            decorationLayer
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerBar
                    modeChips
                    featuredCard
                    quickActionsRow
                    scenesGrid
                    builtinScenesPreview
                    myMixesSection
                    moodFooter
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await engine.refresh()
            modeId = engine.snapshot.selectedMode
        }
    }

    private var decorationLayer: some View {
        ZStack {
            Image(systemName: "leaf.fill")
                .font(.system(size: 220, weight: .heavy))
                .foregroundStyle(Palette.lime.opacity(0.07))
                .rotationEffect(.degrees(-25))
                .offset(x: -130, y: -260)
            Image(systemName: "leaf.fill")
                .font(.system(size: 180, weight: .heavy))
                .foregroundStyle(Palette.aqua.opacity(0.05))
                .rotationEffect(.degrees(160))
                .offset(x: 150, y: -120)
            Image(systemName: "drop.fill")
                .font(.system(size: 120, weight: .heavy))
                .foregroundStyle(Palette.azure.opacity(0.05))
                .offset(x: 130, y: 220)
        }
        .allowsHitTesting(false)
    }

    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Buonasera")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.aqua)
                    .textCase(.uppercase)
                    .tracking(1.5)
                Text("Cosa ascolti oggi?")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.textLight)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Palette.aqua, Palette.azure],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .shadow(color: Palette.aqua.opacity(0.5), radius: 12)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(Palette.gold)
            }
        }
        .padding(.top, 4)
    }

    private var modeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(modes, id: \.id) { mode in
                    let active = modeId == mode.id
                    Button {
                        modeId = mode.id
                        Task { await journal.setSelectedMode(mode.id); await engine.refresh() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.system(size: 12, weight: .heavy))
                            Text(mode.title)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .fixedSize()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(active ? mode.hue : Palette.panelMid)
                        )
                        .foregroundStyle(active ? Palette.backgroundDeep : Palette.textLight)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
        }
        .padding(.horizontal, -18)
    }

    private var featuredCard: some View {
        FeaturedScenePanel(
            title: featured.title,
            subtitle: featured.subtitle,
            assetName: featured.asset,
            palette: featured.mood.skyPalette
        ) {
            Task { await engine.loadPreset(featured.mix) }
        }
    }

    private var quickActionsRow: some View {
        HStack(spacing: 8) {
            ForEach(Array(quickActions.enumerated()), id: \.offset) { _, action in
                Button {
                    startTabRaw = action.tab.rawValue
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(action.tint.opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: action.symbol)
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundStyle(action.tint)
                        }
                        Text(action.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.textLight)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Palette.panelMid.opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var scenesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("home.scenes")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(scenes.enumerated()), id: \.offset) { _, scene in
                    ScenePanel(title: scene.title, mood: scene.mood,
                               assetName: scene.asset, accent: scene.accent) {
                        Task { await engine.loadPreset(scene.mix) }
                    }
                    .aspectRatio(1.0, contentMode: .fit)
                }
            }
        }
    }

    private var builtinScenesPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("presets.builtin")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SoundMix.builtinScenes.prefix(4)) { mix in
                        Button {
                            Task { await engine.loadPreset(mix) }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Palette.panelHigh)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(Palette.gold)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mix.name)
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Palette.textLight)
                                        .lineLimit(1)
                                    Text("\(mix.activeKeys.count) suoni")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundStyle(Palette.textSecondary)
                                }
                            }
                            .padding(10)
                            .frame(width: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Palette.panelMid.opacity(0.7))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var myMixesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("home.my_mixes")
            let recent = Array(engine.snapshot.presets.prefix(3))
            switch recent.isEmpty {
            case true:
                emptyMixPanel
            case false:
                VStack(spacing: 8) {
                    ForEach(recent) { mix in
                        mixRow(mix)
                    }
                }
            }
        }
    }

    private var emptyMixPanel: some View {
        Button {
            startTabRaw = RootTab.mixer.rawValue
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Palette.gold, Palette.coral],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(Palette.backgroundDeep)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("home.new_mix")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.textLight)
                    Text("Apri il mixer e componi la tua atmosfera")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.panelMid.opacity(0.7))
            )
        }
        .buttonStyle(.plain)
    }

    private func mixRow(_ mix: SoundMix) -> some View {
        Button {
            Task { await engine.loadPreset(mix) }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.panelHigh)
                        .frame(width: 46, height: 46)
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Palette.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(mix.name)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.textLight)
                    Text("\(mix.activeKeys.count) suoni")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.panelMid.opacity(0.7))
            )
        }
        .buttonStyle(.plain)
    }

    private var moodFooter: some View {
        HStack(spacing: 14) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Palette.gold)
            VStack(alignment: .leading, spacing: 4) {
                Text("Foresta sempre con te")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.textLight)
                Text("Crea, salva e riprendi i tuoi paesaggi sonori")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [Palette.panelMid, Palette.panelHigh.opacity(0.8)],
                                     startPoint: .leading, endPoint: .trailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Palette.gold.opacity(0.25), lineWidth: 1)
        )
    }

    private func sectionHeader(_ key: LocalizedStringKey) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textLight)
            Spacer()
        }
    }
}
