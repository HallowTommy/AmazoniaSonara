import SwiftUI
import AVFoundation

@main
struct ForestaSonoraApp: App {
    private let journal = SoundscapeJournal()
    @StateObject private var engine = AudioEngine()

    init() {
        GateProbe.bootstrap(host: AppConfig.relayHost,
                            key: AppConfig.relayKey,
                            deadline: AppConfig.relayDeadline,
                            streams: AppConfig.relayTargets)
        configureAudioSession()
        configureNavigationAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.soundscape, journal)
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .task {
                    await journal.hydrate()
                    await engine.bind(journal: journal)
                }
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
        }
    }

    private func configureNavigationAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Palette.backgroundDeep)
        nav.titleTextAttributes = [.foregroundColor: UIColor(Palette.textLight)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Palette.textLight)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Palette.panelMid)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
