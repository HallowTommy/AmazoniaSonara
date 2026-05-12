import SwiftUI

struct ContentView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false

    var body: some View {
        GateRouterView {
            Group {
                switch onboardingDone {
                case true:  RootTabView()
                case false: OnboardingView()
                }
            }
        } carrier: { url in
            BridgeWebView(url: url)
        }
    }
}

struct RootTabView: View {
    @AppStorage("startTab") private var startTabRaw: String = "home"

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: tabBinding) {
                NavigationStack { HomeView() }
                    .tabItem { Label("tab.home", systemImage: "house.fill") }
                    .tag(RootTab.home)

                NavigationStack { MixerView() }
                    .tabItem { Label("tab.mixer", systemImage: "slider.horizontal.3") }
                    .tag(RootTab.mixer)

                NavigationStack { SleepTimerView() }
                    .tabItem { Label("tab.timer", systemImage: "moon.zzz.fill") }
                    .tag(RootTab.timer)

                NavigationStack { PresetsView() }
                    .tabItem { Label("tab.presets", systemImage: "square.stack.fill") }
                    .tag(RootTab.presets)

                NavigationStack { ProfileView() }
                    .tabItem { Label("tab.profile", systemImage: "person.crop.circle") }
                    .tag(RootTab.profile)
            }
            .tint(Palette.turquoise)

            MiniPlayer()
                .padding(.bottom, 78)
        }
    }

    private var tabBinding: Binding<RootTab> {
        Binding(
            get: { RootTab(raw: startTabRaw) ?? .home },
            set: { startTabRaw = $0.rawValue }
        )
    }
}

enum RootTab: String, Hashable {
    case home, mixer, timer, presets, profile

    init?(raw: String) {
        self.init(rawValue: raw)
    }
}
